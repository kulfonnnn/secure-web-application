import nh3

# Formatting allowed in posts, everything else is stripped
ALLOWED_TAGS = {
    "p", "br", "strong", "em", "u", "s", "a",
    "ul", "ol", "li", "blockquote", "pre", "code",
}
ALLOWED_ATTRIBUTES = {"a": {"href", "title"}}
ALLOWED_URL_SCHEMES = {"http", "https", "mailto"}


def sanitize_html(html):
    return nh3.clean(
        html,
        tags=ALLOWED_TAGS,
        attributes=ALLOWED_ATTRIBUTES,
        url_schemes=ALLOWED_URL_SCHEMES,
        link_rel="noopener noreferrer nofollow",
    )


def visible_text(html):
    # Text left after removing all tags
    return nh3.clean(html, tags=set()).strip()
