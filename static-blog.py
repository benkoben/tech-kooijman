import os

from markdown2 import markdown
from jinja2 import Environment, PackageLoader, select_autoescape
from datetime import datetime

CONTENT_FOLDER=os.path.abspath('content/active_articles')
OUT_FOLDER=os.path.abspath('content/out')

env = Environment(
    loader=PackageLoader("static-blog"),
    autoescape=select_autoescape()
)

active_articles = os.listdir(CONTENT_FOLDER)
homepage = env.get_template('homePage.html')
postpage = env.get_template('postPage.html')
aboutpage = env.get_template('aboutPage.html')

posts = dict()
date_sort_func = lambda x: datetime.strptime(posts[x]['date'], '%Y-%m-%d') 

print("Following files are active blog posts:")
print('fileName '.ljust(25, '_'), 'date')
for article_file in active_articles:
    md_obj = markdown(
        open(f'{CONTENT_FOLDER}/{article_file}', 'r').read(),
        extras=['metadata']
    )

    print(f'{article_file} '.ljust(25, '_'), md_obj.metadata['date'])
    posts[md_obj.metadata['slug']] = {
        'title': md_obj.metadata['title'],
        'date': md_obj.metadata['date'],
        'summary': md_obj.metadata['summary'],
        'slug': md_obj.metadata['slug'],
        'content': md_obj
    }

about_md_obj = markdown(
    open(f'{CONTENT_FOLDER}/about.md', 'r').read(),
    extras=['metadata']
)

data = {
    x: posts[x] for x in sorted(posts, key=date_sort_func) if x != "about-page"
}

# Render landing page
with open(f'{OUT_FOLDER}/index.html', 'w+') as index_file:
    index_file.write(homepage.render(posts=data))

# Render posts
for post, content in data.items():
    with open(f'{OUT_FOLDER}/posts/{post}.html', 'w+') as post_file:
        post_file.write(postpage.render(post=content))

# Render about page
with open(f'{OUT_FOLDER}/about.html', 'w+') as about_file:
    about_file.write(aboutpage.render(content=about_md_obj))
