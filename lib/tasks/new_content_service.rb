require 'hydra/file_characterization'
require 'tasks/task_logger'

Hydra::FileCharacterization::Characterizers::Fits.tool_path = `which fits || which fits.sh`.strip

class NewContentService

  class TaskConfigError < RuntimeException
  end

  class UserNotFoundError < RuntimeException
  end

  class VisibilityError < RuntimeException
  end

  class WorkNotFoundError < RuntimeException
  end

  attr_reader :cfg, :base_path, :user

  def initialize( config, base_path )
    initialize_with_msg( config, base_path )
  end

  def run
    validate_config
    build_repo_contents
  rescue TaskConfigError => e
    logger.error e.message.to_s
  rescue UserNotFoundError => e
    logger.error e.message.to_s
  rescue VisibilityError => e
    logger.error e.message.to_s
  rescue WorkNotFoundError => e
    logger.error e.message.to_s
  rescue Exception => e # rubocop:disable Lint/RescueException
    logger.error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
  end

  protected

    def add_file_sets_to_work( work_hash, work )
      paths_and_names = work_hash[:files].zip work_hash[:filenames]
      fsets = paths_and_names.map { |fp| build_file_set(fp[0], fp[1]) }
      fsets.each do |fs|
        work.ordered_members << fs
        # work.total_file_size_add_file_set fs # TODO
        work.representative = fs if work.representative_id.blank?
        work.thumbnail = fs if work.thumbnail_id.blank?
      end
      return work
    end

    def build_collection( collection_hash )
      title = collection_hash['title']
      desc  = collection_hash['desc']
      col = Collection.new( title: title, description: desc, creator: Array(user_key) )
      col.apply_depositor_metadata( user_key )

      # Build all the works in the collection
      works_info = Array(collection_hash['works'])
      c_works = works_info.map { |w| build_work(w) }

      # Add each work to the collection (see CollectionBehavior#add_member_objects)
      c_works.each do |cw|
        cw.member_of_collections << self
        cw.save!
      end

      col.save!
    end

    def build_collections
      return unless collections
      collections.each { |collection_hash| build_collection( collection_hash ) }
    end

    def build_file_set( path, filename = nil )
      # If filename not given, use basename from path
      fname = filename || File.basename(path)
      logger.info "Processing: #{fname}"
      file = File.open(path)
      # fix so that filename comes from the name of the file and not the hash
      file.define_singleton_method( :original_name ) do
        fname
      end

      fs = FileSet.new
      fs.apply_depositor_metadata(user_key)
      Hydra::Works::UploadFileToFileSet.call(fs, file)
      fs.title = Array(fname)
      fs.label = fname
      now = DateTime.now.new_offset(0)
      fs.date_uploaded = now
      fs.visibility = visibility
      fs.save!
      repository_file_id = nil
      IngestHelper.characterize(fs, repository_file_id, path, delete_input_file: false, continue_job_chain: false )
      IngestHelper.create_derivatives(fs, repository_file_id, path, delete_input_file: false )
      logger.info "Finished:   #{fname}"
      return fs
    end

    def build_repo_contents
      # override with something interesting
    end

    def build_works
      return unless works
      works.each do |work_hash|
        work = build_work( work_hash )
        log_object work
      end
    end

    def build_work( work_hash )
      source = yaml_source
      title = Array(work_hash[:title])
      creator = Array(work_hash[:creator])
      authoremail = work_hash[:authoremail] || "contact@umich.edu"
      rights_statement = if 'DBDv1' == source
                           Array(work_hash[:rights])
                         else
                           Array(work_hash[:rights_statement])
                         end
      desc = Array(work_hash[:description])
      methodology = work_hash[:methodology] || "No Methodology Available"
      subject = Array(work_hash[:subject])
      contributor = Array(work_hash[:contributor])
      date_uploaded = work_hash[:date_uploaded]
      date_modified = work_hash[:date_modified]
      date_created = work_hash[:date_created]
      date_coverage = Array(work_hash[:date_coverage])
      rtype = Array(work_hash[:resource_type] || 'Dataset')
      language = Array(work_hash[:language])
      keyword = Array(work_hash[:keyword])
      isReferencedBy = Array(work_hash[:isReferencedBy]) # rubocop:disable Style/VariableName

      work = DataSet.new( title: title,
                          creator: creator,
                          authoremail: authoremail,
                          rights_statement: rights_statement,
                          description: desc,
                          resource_type: rtype,
                          methodology: methodology,
                          subject: subject,
                          contributor: contributor,
                          date_uploaded: date_uploaded,
                          date_modified: date_modified,
                          date_created: date_created,
                          date_coverage: date_coverage,
                          language: language,
                          keyword: keyword,
                          isReferencedBy: isReferencedBy )

      add_file_sets_to_work( work_hash, work )
      work.apply_depositor_metadata( user_key )
      work.owner = user_key
      work.visibility = visibility
      # Put the work in the default admin_set.
      work.update( admin_set: default_admin_set ) # TODO fix
      work.save!
      return work
    end

    def collections
      @cfg[:user][:collections]
    end

    def default_admin_set
      @default_admin_set ||= AdminSet.find( AdminSet::DEFAULT_ID )
      # @default_admin_set ||= AdminSet.find_or_create_default_admin_set_id
    end

    def find_or_create_user
      user = User.find_by(user_key: user_key) || create_user(user_key)
      raise UserNotFoundError, "User not found: #{user_key}" if user.nil?
      return user
    end

    def find_work( work_hash )
      work_id = work_hash[:id]
      id = Array(work_id)
      # owner = Array(work_hash[:owner])
      work = DataSet.find id[0]
      raise UserNotFoundError, "Work not found: #{work_id}" if work.nil?
      return work
    end

    def find_works_and_add_files
      return unless works
      works.each do |work_hash|
        work = find_work( work_hash )
        add_file_sets_to_work( work_hash, work )
        work.apply_depositor_metadata( user_key )
        work.owner = user_key
        work.visibility = visibility
        work.save!
        log_object work
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Rails/Output
    def initialize_with_msg( config, base_path, msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE" )
      verbose_init = false
      puts "ENV['TMPDIR']=#{ENV['TMPDIR']}" if verbose_init
      puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
      tmpdir = ENV['TMPDIR']
      tmpdir = File.absolute_path( './tmp/' ) if tmpdir.blank?
      ENV['_JAVA_OPTIONS'] = "-Djava.io.tmpdir=#{tmpdir}"
      puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
      puts `echo $_JAVA_OPTIONS`.to_s if verbose_init
      @cfg = config
      @base_path = base_path
      logger.info msg unless msg.nil?
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Rails/Output

    def log_object( obj )
      logger.info "id: #{obj.id} title: #{obj.title.first}"
    end

    def logger
      @logger ||= logger_initialize
    end

    def logger_initialize
      # TODO: add some flags to the input yml file for log level and Rails logging integration
      # rubocop:disable Style/Semicolon
      Umrdr::TaskLogger.new(STDOUT).tap { |logger| logger.level = logger_level; Rails.logger = logger }
      # rubocop:enable Style/Semicolon
    end

    def logger_level
      return config_value( :logger_level, 'info' )
    end

    def user_key
      # TODO: validate the email
      @cfg[:user][:email]
    end

    def config_value( key, default_value )
      rv = default_value
      if @cfg.key? :config
        rv = @cfg[:config][key] if @cfg[:config].key? key
      end
      return rv
    end

    # config needs default user to attribute collections/works/filesets to
    # User needs to have only works or collections
    def validate_config
      # if @cfg.keys != [:user]
      unless @cfg.key?( :user )
        raise TaskConfigError, "Top level keys needs to contain 'user'"
      end
      # rubocop:disable Style/GuardClause
      if (@cfg[:user].keys <=> %i[collections works]) < 1
        raise TaskConfigError, "user can only contain collections and works"
      end
      # rubocop:enable Style/GuardClause
    end

    def visibility
      @visibility ||= visibility_from_config
    end

    def visibility_from_config
      rv = @cfg[:user][:visibility]
      unless %w[open restricted].include? rv
        raise VisibilityError, "Illegal value '#{rv}' for visibility"
      end
      return rv
    end

    def works
      [@cfg[:user][:works]]
    end

    def yaml_source
      rv = @cfg[:user][:source]
      return rv
    end

end
