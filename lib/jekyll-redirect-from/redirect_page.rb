# frozen_string_literal: true

require 'uri'

module JekyllRedirectFrom
  # Specialty page which implements the redirect path logic
  class RedirectPage < Jekyll::Page
    # Use Jekyll's native absolute_url filter
    include Jekyll::Filters::URLFilters

    DEFAULT_DATA = {
      "sitemap" => false,
      "layout"  => "redirect",
    }.freeze

    # Creates a new RedirectPage instance from a source path and redirect path
    #
    # site - The Site object
    # from - the (URL) path, relative to the site root to redirect from
    # to   - the relative path or URL which the page should redirect to
    def self.from_paths(site, from, to)
      page = RedirectPage.new(site, site.source, "", "redirect.html")
      page.set_paths(from, to)
      page
    end

    # Creates a new RedirectPage instance from the path to the given doc
    def self.redirect_from(doc, path)
      RedirectPage.from_paths(doc.site, path, doc.url)
    end

    # Creates a new RedirectPage instance from the doc to the given path
    def self.redirect_to(doc, path)
      RedirectPage.from_paths(doc.site, doc.url, path)
    end

    # Overwrite the default read_yaml method since the file doesn't exist
    def read_yaml(_base, _name, _opts = {})
      self.content = self.output = ""
      self.data ||= DEFAULT_DATA.dup
    end

    # Helper function to set the appropriate path metadata
    #
    # from - the relative path to the redirect page
    # to   - the relative path or absolute URL to the redirect target
    def set_paths(from, to)
      new_uri_to = to
      if ! to.match?("^https?://[a-zA-Z0-9:._-]+/")
          uri_to = URI(to)
          uri_to_host = uri_to.host
          uri_to_prod = URI("https://software.hifis.net/")
          uri_to_prod_host = uri_to_prod.host
          if uri_to_host.nil? || uri_to_host != uri_to_prod_host
            new_uri_to = uri_to.to_s.sub! uri_to.to_s.partition("https?://[a-zA-Z0-9:._-]+/")[1], "http://localhost:4000"
          else
            new_uri_to = absolute_url(to)
          end
      end

      @context ||= context
      from = ensure_leading_slash(from)
      data.merge!(
        "permalink" => from,
        "redirect"  => {
          "from" => from,
          "to"   => new_uri_to,
        }
      )
    end

    def redirect_from
      data["redirect"]["from"] if data["redirect"]
    end

    def redirect_to
      data["redirect"]["to"] if data["redirect"]
    end

    private

    def context
      JekyllRedirectFrom::Context.new(site)
    end
  end
end
