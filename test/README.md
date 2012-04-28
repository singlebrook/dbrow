Setup dbrow Unit Tests
================

1. Download mxunit and put it in a reasonable place, like `/Users/jared/git/mxunit/`
1. In CF Admin, add two mappings:
  1. Map `/mxunit` to `/Users/jared/git/mxunit`
  1. Map `/dbrow` to `/Users/jared/git/dbrow`
1. In apache vhosts, add something like this:    

        <VirtualHost *:80>
          ServerName dbrow.localhost
          DocumentRoot /Users/jared/git/singlebrook/dbrow/test
          Include /private/etc/apache2/extra/cf9.conf
          Alias /CFIDE/ "/Library/WebServer/Documents/ColdFusion9/CFIDE/"
          Alias /mxunit/ "/Users/jared/git/mxunit/"
        </VirtualHost>
