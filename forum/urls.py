from django.urls import path
from . import views

app_name = 'forum'

urlpatterns = [
    path('', views.forum_list_view, name='forum_list'),
    path('<int:forum_id>/', views.topic_list_view, name='topic_list'),
    path('<int:forum_id>/new/', views.topic_create_view, name='topic_create'),
    path('topic/<int:topic_id>/', views.topic_detail_view, name='topic_detail'),
    path('post/<int:post_id>/edit/', views.post_edit_view, name='post_edit'),
    path('post/<int:post_id>/delete/', views.post_delete_view, name='post_delete'),
    path('post/<int:post_id>/attachment/', views.attachment_download_view, name='attachment_download'),
]
