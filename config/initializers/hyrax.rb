# frozen_string_literal: true

Hyrax.config do |config|

  config.register_curation_concern :data_set
  config.register_curation_concern :dissertation
  # config.register_curation_concern :generic_work
  # Injected via `rails g hyrax:work TestWork`
  config.register_curation_concern :test_work

  # Register roles that are expected by your implementation.
  # @see Hyrax::RoleRegistry for additional details.
  # @note there are magical roles as defined in Hyrax::RoleRegistry::MAGIC_ROLES
  # config.register_roles do |registry|
  #   registry.add(name: 'captaining', description: 'For those that really like the front lines')
  # end

  # When an admin set is created, we need to activate a workflow.
  # The :default_active_workflow_name is the name of the workflow we will activate.
  # @see Hyrax::Configuration for additional details and defaults.
  # config.default_active_workflow_name = 'default'

  # Which RDF term should be used to relate objects to an admin set?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:isPartOf) for other relations.
  # config.admin_set_predicate = ::RDF::DC.isPartOf

  # Which RDF term should be used to relate objects to a rendering?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:hasFormat) for other relations.
  # config.rendering_predicate = ::RDF::DC.hasFormat

  # Email recipient of messages sent via the contact form
  # config.contact_email = "repo-admin@example.org"
  # config.contact_email = Settings.hyrax.contact_email
  config.contact_email = Settings.notification_email_contact_us_to

  # Text prefacing the subject entered in the contact form
  # config.subject_prefix = "Contact form:"

  # How many notifications should be displayed on the dashboard
  # config.max_notifications_for_dashboard = 5

  # How frequently should a file be fixity checked
  # config.max_days_between_fixity_checks = 7

  # Options to control the file uploader
  # Run `bundle exec rake tmp:cache:clear` to clear all the contents of public/assets
  # Run `bundle exec rake assets:clobber assets:precompile` in dev for this to take effect
  # If updating maxNumberOfFiles: 100, # Also update: Rails.configuration.upload_max_number_of_files
  # If updating maxFileSize: 5.gigabytes, # Also update: Rails.configuration.upload_max_file_size
  if Rails.env.test?
    uploader_url = '/uploads'
  else
    uploader_url = Rails.configuration.relative_url_root + '/uploads' # monkey: Rails.configuration.relative_url_root
  end
  config.uploader = {
      limitConcurrentUploads: 6,
      maxNumberOfFiles: 100,
      maxFileSize: 5.gigabytes,
      url: uploader_url
  }

  # Enable displaying usage statistics in the UI
  # Defaults to false
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  config.analytics = true

  # Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = Rails.application.secrets.analytics_id
  path = "#{Rails.application.config.paths["config"].existent.first}/analytics_id.yml"
  if File.exist? path
    Settings.analytics_id ||= Rails.application.config_for(:analytics_id)
    config.google_analytics_id = Settings.analytics_id['analytics_id']
  else
    config.google_analytics_id = nil
  end

  # Date you wish to start collecting Google Analytic statistics for
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # This is the date on the UMRDR WorkViewStat table record number 1
  config.analytic_start_date = DateTime.new(2016, 4, 10 )

  # Enables a link to the citations page for a work
  # Default is false
  config.citations = true

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'
  config.temp_file_base = File.join( Rails.root, 'tmp', 'derivatives') # rubocop:disable Rails/FilePath

  # Hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video set to true
  # config.enable_ffmpeg = false

  # Hyrax uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Use the database-backed minter class
  # config.noid_minter_class = Noid::Rails::Minter::Db

  # Store identifier minter's state in a file for later replayability
  # config.minter_statefile = '/tmp/minter-state'
  config.minter_statefile = Settings.hyrax.minter_statefile

  # Prefix for Redis keys
  # config.redis_namespace = "hyrax"
  config.redis_namespace = Settings.hyrax.redis_namespace

  # Path to the file characterization tool
  # config.fits_path = "fits.sh"
  if system( "which", "fits.sh" )
    config.fits_path = "fits.sh"
  else
    file_path = File.expand_path '~/fits/fits.sh'
    if File.exist? file_path
      config.fits_path = file_path
    else
      # config.fits_path = "/l/local/fits/fits.sh"
      config.fits_path = file_path
    end
  end
  # config.fits_path = system("which", "fits.sh") ? "fits.sh" : "/l/local/fits/fits.sh"

  # Path to the file derivatives creation tool
  # config.libreoffice_path = "soffice"

  # Option to enable/disable full text extraction from PDFs
  # Default is true, set to false to disable full text extraction
  # config.extract_full_text = true

  # How many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # config.arkivo_api = false

  # Stream realtime notifications to users in the browser
  # config.realtime_notifications = true

  # Location autocomplete uses geonames to search for named regions
  # Username for connecting to geonames
  config.geonames_username = ''

  # Should the acceptance of the licence agreement be active (checkbox), or
  # implied when the save button is pressed? Set to true for active
  # The default is true.
  # config.active_deposit_agreement_acceptance = true

  # Should work creation require file upload, or can a work be created first
  # and a file added at a later time?
  # The default is true.
  config.work_requires_files = false

  # Enable IIIF image service. This is required to use the
  # UniversalViewer-ified show page
  #
  # If you have run the riiif generator, an embedded riiif service
  # will be used to deliver images via IIIF. If you have not, you will
  # need to configure the following other configuration values to work
  # with your image server:
  #
  #   * iiif_image_url_builder
  #   * iiif_info_url_builder
  #   * iiif_image_compliance_level_uri
  #   * iiif_image_size_default
  #
  # Default is false
  # config.iiif_image_server = false

  # Returns a URL that resolves to an image provided by a IIIF image server
  config.iiif_image_url_builder = lambda do |file_id, base_url, size|
    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size: size)
  end
  # config.iiif_image_url_builder = lambda do |file_id, base_url, size|
  #   "#{base_url}/downloads/#{file_id.split('/').first}"
  # end

  # Returns a URL that resolves to an info.json file provided by a IIIF image server
  config.iiif_info_url_builder = lambda do |file_id, base_url|
    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
    uri.sub(%r{/info\.json\Z}, '')
  end
  # config.iiif_info_url_builder = lambda do |_, _|
  #   ""
  # end

  # Returns a URL that indicates your IIIF image server compliance level
  # config.iiif_image_compliance_level_uri = 'http://iiif.io/api/image/2/level2.json'

  # Returns a IIIF image size default
  # config.iiif_image_size_default = '600,'

  # Fields to display in the IIIF metadata section; default is the required fields
  # config.iiif_metadata_fields = Hyrax::Forms::WorkForm.required_fields

  # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
  # config.display_share_button_when_not_logged_in = true

  # The user who runs batch jobs. Update this if you aren't using emails
  # config.batch_user_key = 'batchuser@example.com'

  # The user who runs fixity check jobs. Update this if you aren't using emails
  # config.audit_user_key = 'audituser@example.com'
  #
  # The banner image. Should be 5000px wide by 1000px tall
  # config.banner_image = 'https://cloud.githubusercontent.com/assets/92044/18370978/88ecac20-75f6-11e6-8399-6536640ef695.jpg'

  # Temporary paths to hold uploads before they are ingested into FCrepo
  # These must be lambdas that return a Pathname. Can be configured separately
  #  config.upload_path = ->() { Rails.root + 'tmp' + 'uploads' }
  #  config.cache_path = ->() { Rails.root + 'tmp' + 'uploads' + 'cache' }

  # Location on local file system where derivatives will be stored
  # If you use a multi-server architecture, this MUST be a shared volume
  # config.derivatives_path = Rails.root.join('tmp', 'derivatives')

  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.working_path = Rails.root.join( 'tmp', 'uploads')

  # Should the media display partial render a download link?
  # config.display_media_download_link = true

  # A configuration point for changing the behavior of the license service
  #   @see Hyrax::LicenseService for implementation details
  # config.license_service_class = Hyrax::LicenseService

  # Labels for display of permission levels
  # config.permission_levels = { "View/Download" => "read", "Edit access" => "edit" }

  # Labels for permission level options used in dropdown menus
  # config.permission_options = { "Choose Access" => "none", "View/Download" => "read", "Edit" => "edit" }

  # Labels for owner permission levels
  # config.owner_permission_levels = { "Edit Access" => "edit" }

  # Path to the ffmpeg tool
  # config.ffmpeg_path = 'ffmpeg'

  # Max length of FITS messages to display in UI
  # config.fits_message_length = 5

  # ActiveJob queue to handle ingest-like jobs
  # config.ingest_queue_name = :default
  config.ingest_queue_name = :ingest

  ## Attributes for the lock manager which ensures a single process/thread is mutating a ore:Aggregation at once.
  # How many times to retry to acquire the lock before raising UnableToAcquireLockError
  # config.lock_retry_count = 600 # Up to 2 minutes of trying at intervals up to 200ms
  #
  # Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
  # config.lock_retry_delay = 200
  #
  # How long to hold the lock in milliseconds
  # config.lock_time_to_live = 60_000

  ## Do not alter unless you understand how ActiveFedora handles URI/ID translation
  # config.translate_id_to_uri = lambda do |uri|
  #                                baseparts = 2 + [(Noid::Rails::Config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
  #                                uri.to_s.sub(baseurl, '').split('/', baseparts).last
  #                              end
  # config.translate_uri_to_id = lambda do |id|
  #                                "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{Noid::Rails.treeify(id)}"
  #                              end

  ## Fedora import/export tool
  #
  # Path to the Fedora import export tool jar file
  # config.import_export_jar_file_path = "tmp/fcrepo-import-export.jar"
  #
  # Location where BagIt files should be exported
  # config.bagit_dir = "tmp/descriptions"

  # This enables or disables the ability to download files.
  config.define_singleton_method(:download_files) do
    return true
  end

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end
  # config.browse_everything = nil # disable browse_everything

  ## Whitelist all directories which can be used to ingest from the local file
  # system.
  #
  # Any file, and only those, that is anywhere under one of the specified
  # directories can be used by CreateWithRemoteFilesActor to add local files
  # to works. Files uploaded by the user are handled separately and the
  # temporary directory for those need not be included here.
  #
  # Default value includes BrowseEverything.config['file_system'][:home] if it
  # is set, otherwise default is an empty list. You should only need to change
  # this if you have custom ingestions using CreateWithRemoteFilesActor to
  # ingest files from the file system that are not part of the BrowseEverything
  # mount point.
  #
  # config.whitelisted_ingest_dirs = []

  # rubocop#:disable Rails/Output
  # Doing this before adding actors freezes the stack
  # # print out the actor stack
  # actor = Hyrax::CurationConcern.actor
  # puts "Hyrax::CurationConcern.actor stack"
  # loop do
  #   puts "actor: #{actor.class.name}"
  #   break if actor.nil?
  #   break unless actor.respond_to? :next_actor
  #   actor = actor.next_actor
  # end

  # see Hyrax::DefaultMiddlewareStack.build_stack
  Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::OptimisticLockValidator, Hyrax::Actors::AfterOptimisticLockValidator
  Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::CollectionsMembershipActor, Hyrax::Actors::BeforeAddToWorkActor
  Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::AddToWorkActor, Hyrax::Actors::BeforeAttachMembersActor
  Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::FeaturedWorkActor, Hyrax::Actors::BeforeModelActor

  # turn this on to see verify the stack
  # actor = Hyrax::CurationConcern.actor
  # puts "Hyrax::CurationConcern.actor stack after inserts"
  # loop do
  #   puts "#{actor.class.name}"
  #   break if actor.nil?
  #   break unless actor.respond_to? :next_actor
  #   actor = actor.next_actor
  # end
  # rubocop#:enable Rails/Output

  # override the path used for branding
  # the rest of the code assumes that the this path is symlinked to public/branding
  config.instance_variable_set( :@branding_path, Rails.root.join( 'data', 'branding' ) )

end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

Qa::Authorities::Local.register_subauthority('subjects', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('languages', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('genres', 'Qa::Authorities::Local::TableBasedAuthority')
