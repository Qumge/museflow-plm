# Be sure to restart your server when you modify this file.
#
# This file configures Rails 7.0 framework defaults.
# Values here override values in config/application.rb when config.load_defaults 7.0 is set.
# We selectively disable new defaults that may break existing behavior.

# Don't force SameSite=Lax on all cookies (keep existing behavior)
# Rails.application.config.action_dispatch.cookies_same_site_protection = :lax

# Keep legacy connection handling
Rails.application.config.active_record.verify_foreign_keys_for_fixtures = false

# Disable automatic has_many inverse detection to keep existing behavior
# Rails.application.config.active_record.automatic_scope_inversing = true

# Keep existing cache format
Rails.application.config.active_support.cache_format_version = 6.1

# Digest class
Rails.application.config.active_support.hash_digest_class = OpenSSL::Digest::MD5

# Key generator hash digest class
Rails.application.config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
