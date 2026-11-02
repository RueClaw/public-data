"""Conservative, scriptless presentation of repository HTML guides."""
from html import escape
from html.parser import HTMLParser
from urllib.parse import urlsplit

GUIDE_CSP = ("sandbox; default-src 'none'; script-src 'none'; style-src 'unsafe-inline'; "
             "img-src data:; connect-src 'none'; font-src 'none'; object-src 'none'; "
             "frame-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'")

class SafeGuide(HTMLParser):
    tags = set('html head body title style main header footer nav section article aside div span p h1 h2 h3 h4 h5 h6 a ul ol li dl dt dd table thead tbody tfoot tr th td caption pre code blockquote strong em b i small sup sub br hr details summary figure figcaption'.split())
    void = {'br', 'hr', 'img', 'input', 'meta', 'link', 'embed', 'source', 'wbr'}
    blocked_tags = {'script', 'iframe', 'object', 'embed', 'svg', 'math', 'form', 'template', 'video', 'audio', 'canvas'}
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.output = ['<!doctype html>']
        self.blocked = []
        self.in_style = False
    def handle_starttag(self, tag, attrs):
        if self.blocked:
            if tag not in self.void: self.blocked.append(tag)
            return
        if tag in self.blocked_tags:
            if tag not in self.void: self.blocked.append(tag)
            return
        if tag == 'button': tag = 'span'
        if tag not in self.tags: return
        clean = []
        for name, value in attrs:
            if value is None: continue
            if name in {'class', 'id', 'title', 'lang', 'dir', 'colspan', 'rowspan', 'aria-label'}:
                clean.append((name, value))
            elif name == 'href' and tag == 'a':
                try:
                    u = urlsplit(value.strip())
                except ValueError:
                    continue
                if value.startswith('#') or (u.scheme in ('https', 'http') and u.hostname and not u.username and not u.password):
                    clean.extend([('href', value), ('rel', 'noopener noreferrer')])
        # No event handlers, style attributes, data URLs, forms or external assets.
        self.output.append('<' + tag + ''.join(f' {k}="{escape(v, quote=True)}"' for k,v in clean) + '>')
        if tag == 'style': self.in_style = True
    def handle_endtag(self, tag):
        if self.blocked:
            if tag in self.blocked:
                self.blocked = self.blocked[:len(self.blocked)-1-self.blocked[::-1].index(tag)]
            return
        if tag == 'button': tag = 'span'
        if tag in self.tags and tag not in self.void:
            if tag == 'head':
                self.output.append('<style>.panel,.tab-panel,.tab-content,.tab-pane,[role="tabpanel"]{display:block!important}html{scroll-behavior:smooth}body:before{content:"Safe reading mode · scripts and external resources disabled";display:block;padding:10px 20px;font:12px system-ui;background:#252536;color:#cdd6f4}button,[role="tablist"]{display:none!important}</style>')
            self.output.append('</' + tag + '>')
        if tag == 'style': self.in_style = False
    def handle_data(self, data):
        if not self.blocked: self.output.append(data if self.in_style else escape(data))

def sanitize_guide(source):
    parser = SafeGuide()
    parser.feed(source)
    parser.close()
    return ''.join(parser.output).encode()
