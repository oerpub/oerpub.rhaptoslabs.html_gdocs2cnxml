from setuptools import setup, find_packages
import os

version = '1.1'

long_description = (
    open('README.rst').read()
    + '\n' +
    open('CHANGES.txt').read()
    + '\n')

setup(name='oerpub.rhaptoslabs.html_gdocs2cnxml',
      version=version,
      description="Convert HTML, GDocs and Word HTML to CNXML",
      long_description=long_description,
      # Get more strings from
      # http://pypi.python.org/pypi?%3Aaction=list_classifiers
      classifiers=[
        "Programming Language :: Python",
        ],
      keywords='',
      author='Marvin Reimer',
      author_email='',
      url='https://github.com/oerpub/oerpub.rhaptoslabs.html_gdocs2cnxml',
      license='gpl',
      packages=find_packages('src'),
      package_dir = {'': 'src'},
      namespace_packages=['oerpub', 'oerpub.rhaptoslabs'],
      include_package_data=True,
      zip_safe=False,
      dependency_links = [
          'http://code.google.com/p/gdata-python-client/downloads/list'
      ],
      install_requires=[
          'setuptools',
          # -*- Extra requirements: -*-
          'pytidylib>=0.2.1',
          'lxml>=2.3',
          'gdata==2.0.14',
          'readability-lxml',
      ],
      entry_points="""
      # -*- Entry points: -*-
      """,
      )
