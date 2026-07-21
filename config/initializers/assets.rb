# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add vendor/assets/fonts to the asset load path
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')

# cytoscape is only needed on the relationship-graph page (app/views/home/cytoscape.html.erb),
# so it's no longer required globally from application.js and is instead included directly
# by app/views/layouts/cytoscape.html.erb via javascript_include_tag 'cytoscape'.
#
# It lives in vendor/assets/javascripts/, which app/assets/config/manifest.js's
# `link_directory ../javascripts .js` does NOT cover (that only picks up top-level files
# under app/assets/javascripts/). Without this, `javascript_include_tag 'cytoscape'` works
# fine in development (config.assets.compile = true lets Sprockets compile on demand) but
# 404s in production, where config.assets.compile = false and only precompiled assets are
# servable. Explicitly precompiling it here keeps the two environments in sync.
Rails.application.config.assets.precompile += %w( cytoscape.js )
