
Deepblue::MarkdownService.setup do |config|

  config.markdown_service_debug_verbose = false # Warning: big blobs of text spit out if this is true

  config.render_options = {
                        hard_wrap:                    true,
                        safe_links_only:              true
                      }.freeze

  config.extensions = {
                        autolink:                     true,
                        disable_indented_code_blocks: true,
                        lax_spacing:                  true,
                        no_intra_emphasis:            true,
                        strikethrough:                true,
                        tables:                       true,
                        space_after_headers:          true
                      }.freeze

end
