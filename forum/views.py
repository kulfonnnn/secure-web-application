from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.core.exceptions import PermissionDenied
from django.db import transaction
from django.db.models import Count, Max
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from .forms import PostForm, TopicForm
from .models import Forum, Post, Topic


@login_required
def forum_list_view(request):
    forums = Forum.objects.annotate(topic_count=Count('topics'))
    return render(request, 'forum/forum_list.html', {'forums': forums})


@login_required
def topic_list_view(request, forum_id):
    forum = get_object_or_404(Forum, pk=forum_id)
    topics = (
        forum.topics.select_related('author')
        .annotate(post_count=Count('posts'), last_post_at=Max('posts__created_at'))
        .order_by('-last_post_at')
    )
    return render(request, 'forum/topic_list.html', {'forum': forum, 'topics': topics})


@login_required
def topic_create_view(request, forum_id):
    forum = get_object_or_404(Forum, pk=forum_id)
    if request.method == 'POST':
        form = TopicForm(request.POST)
        if form.is_valid():
            # Topic and its first post are saved together
            with transaction.atomic():
                topic = form.save(commit=False)
                topic.forum = forum
                topic.author = request.user
                topic.save()
                Post.objects.create(
                    topic=topic, author=request.user, content=form.cleaned_data['content']
                )
            messages.success(request, 'Topic created.')
            return redirect('forum:topic_detail', topic_id=topic.pk)
    else:
        form = TopicForm()
    return render(request, 'forum/topic_form.html', {'forum': forum, 'form': form})


@login_required
def topic_detail_view(request, topic_id):
    topic = get_object_or_404(Topic.objects.select_related('forum', 'author'), pk=topic_id)
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            post = form.save(commit=False)
            post.topic = topic
            post.author = request.user
            post.save()
            messages.success(request, 'Reply added.')
            return redirect('forum:topic_detail', topic_id=topic.pk)
    else:
        form = PostForm()
    posts = topic.posts.select_related('author')
    return render(request, 'forum/topic_detail.html', {'topic': topic, 'posts': posts, 'form': form})


@login_required
def post_edit_view(request, post_id):
    post = get_object_or_404(Post, pk=post_id)
    # Only the author can edit (changing the id in URL is not enough)
    if post.author != request.user:
        raise PermissionDenied
    if request.method == 'POST':
        form = PostForm(request.POST, instance=post)
        if form.is_valid():
            post = form.save(commit=False)
            post.edited_at = timezone.now()
            post.save()
            messages.success(request, 'Post updated.')
            return redirect('forum:topic_detail', topic_id=post.topic_id)
    else:
        form = PostForm(instance=post)
    return render(request, 'forum/post_form.html', {'post': post, 'form': form})


@login_required
@require_http_methods(['GET', 'POST'])
def post_delete_view(request, post_id):
    post = get_object_or_404(Post.objects.select_related('topic'), pk=post_id)
    # Author or moderator (staff) can delete
    if post.author != request.user and not request.user.is_staff:
        raise PermissionDenied
    topic = post.topic
    first_post_id = topic.posts.order_by('created_at', 'pk').values_list('pk', flat=True).first()
    is_first_post = post.pk == first_post_id
    if request.method == 'POST':
        if is_first_post:
            # Removing the first post removes the whole topic
            forum_id = topic.forum_id
            topic.delete()
            messages.success(request, 'Topic deleted.')
            return redirect('forum:topic_list', forum_id=forum_id)
        post.delete()
        messages.success(request, 'Post deleted.')
        return redirect('forum:topic_detail', topic_id=topic.pk)
    return render(request, 'forum/post_confirm_delete.html', {'post': post, 'is_first_post': is_first_post})
