require 'rails_helper'
class TestController < ApplicationController
   include Deepblue::StaticContentControllerBehavior
end
RSpec.describe Deepblue::StaticContentControllerBehavior do

  let(:dummy_class) { TestController.new }
  let(:test_collection) { double('Collection', id: 'testid', title: ["TestTitle"] ) }
  let(:test_work) { double('Work', tile: "WorkTitle", id: 'abcxyz' ) }
  let(:test_file_set) { double('FileSet', title: ["fileName"], id: 'abcxyz' ) }  
  let(:test_uri) { double('Uri') }  
  let(:test_file) { double('File', title: 'fileName', id: 'abcxyz', uri: test_uri ) }  
  let(:file_like_object) { double("file like object") } 
  let(:send_data) { double('send_data')}
  
  before do
  	allow(dummy_class).to receive(:send_data).and_return ("done")
    allow(Deepblue::WorkViewContentService).to receive(:content_documentation_collection_id).and_return "123"
    allow(Deepblue::WorkViewContentService).to receive(:documentation_i18n_title_prefix).and_return "123"
    allow(Deepblue::StaticContentControllerBehavior).to receive(:static_content_documentation_collection_id).and_return "collid1"
    allow(::Deepblue::WorkViewContentService).to receive(:static_content_enable_cache).and_return "cacheid"
    allow(Collection).to receive(:find).and_return :test_collection
  end

  it 'returns the collection id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_documentation_collection_id
    expect(dc).to eq("collid1")
  end

  it 'sets the cahe id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_id( key: 2, id: 4)
    expect(dc).to eq(4)
  end

  it 'sets the value for the cache based on id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_get( key: 2 )
    expect(dc).to eq(4)
  end

  it 'returns nil value value associated with a non existing id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_get( key: 3 )
    expect(dc).to eq(nil)
  end

  it 'returns value value associated with an existing id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_get( key: 2 )
    expect(dc).to eq(4)
  end

  it 'resets cache and verifies that it is reset' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_reset
    expect(dc).to eq(nil)

    dc = Deepblue::StaticContentControllerBehavior.static_content_cache_get( key: 2 )
    expect(dc).to eq(nil)
  end

  it 'finds nil for invalid id' do
    dc = Deepblue::StaticContentControllerBehavior.static_content_find_by_id(id: nil)
    expect(dc).to eq(nil)
  end

  it 'finds content value for valid id' do
  	allow(::PersistHelper).to receive(:find).and_return("valid_value")

    dc = Deepblue::StaticContentControllerBehavior.static_content_find_by_id(id: "test")  	
    expect(dc).to eq("valid_value")
  end

  it 'returns title prefix for doc' do   
    allow(Deepblue::WorkViewContentService).to receive(:documentation_work_title_prefix).and_return "abc"                          

    dc = dummy_class.documentation_work_title_prefix()
    expect(dc).to eq("abc")
  end

  it 'returns email prefix for doc' do   
    allow(Deepblue::WorkViewContentService).to receive(:documentation_email_title_prefix).and_return "xyz"                          

    dc = dummy_class.documentation_email_title_prefix()
    expect(dc).to eq("xyz")
  end

  it 'returns title prefix for i18n' do  
    allow(Deepblue::WorkViewContentService).to receive(:documentation_i18n_title_prefix).and_return "123"                           

    dc = dummy_class.documentation_i18n_title_prefix()
    expect(dc).to eq("123")
  end

  it 'returns static content menu verbose' do  
    allow(Deepblue::WorkViewContentService).to receive(:static_content_controller_behavior_menu_verbose).and_return "test"                           

    dc = dummy_class.static_content_menu_debug_verbose()
    expect(dc).to eq("test")
  end

  it 'returns documention collection' do                             
    dc = dummy_class.static_content_documentation_collection()
    expect(dc).to eq(:test_collection)
  end

  it 'returns work with the passed in title' do   
  	allow(dummy_class).to receive(:static_content_documentation_collection).and_return(test_collection)
    allow(test_collection).to receive(:member_works).and_return([test_collection])
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil) 

    dc = dummy_class.static_content_find_documentation_work_by_title(title: "TestTitle")
    expect(dc).to eq(test_collection)
  end


  it 'returns fileset by WorkTitle and FileSetTitle' do   
  	allow(dummy_class).to receive(:static_content_find_documentation_work_by_title).and_return(test_work)
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil)  	
    allow(test_work).to receive(:file_sets).and_return([test_file_set])
 
    dc = dummy_class.static_content_find_documentation_file_set( work_title: "WorkTitle", file_name: "fileName", path: "/data" )
    expect(dc).to eq(test_file_set)
  end

  it 'finds content by id' do  
    allow(Deepblue::StaticContentControllerBehavior).to receive(:static_content_find_by_id).and_return("contentValue")               
 
    dc = dummy_class.static_content_find_by_id( id: 1, cache_id_with_key: nil, raise_error: false )
    expect(dc).to eq("contentValue")
  end

  it 'returns file set for static content' do  
  	allow(dummy_class).to receive(:static_content_find_work_by_title).and_return(test_work)
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil) 
    allow(dummy_class).to receive(:static_content_work_file_set_find_by_title).and_return(test_file_set) 	
 
    dc = dummy_class.static_content_file_set( work_title: "WorkTitle", file_set_title: "fileName", path: "/data" )
    expect(dc).to eq(test_file_set)
  end

  it 'returns content based on title with title size 9' do  
  	allow(dummy_class).to receive(:static_content_find_by_id).and_return(nil)
    allow(dummy_class).to receive(:static_content_find_by_id).and_return("content")	
 
    dc = dummy_class.static_content_find_by_title( title: "123456789", id: "abcxyz", solr_query: "")
    expect(dc).to eq("content")
  end

  it 'returns content based on title with title size not 9, but with expected prefix' do  
  	allow(dummy_class).to receive(:static_content_find_by_id).and_return(nil)
    allow(dummy_class).to receive(:documentation_work_title_prefix).and_return("abc")
    allow(dummy_class).to receive(:static_content_find_documentation_work_by_title).and_return("content")    	
 
    dc = dummy_class.static_content_find_by_title( title: "abcTitle", id: "abcxyz", solr_query: "")
    expect(dc).to eq("content")
  end

  it 'returns content based solr query' do  
  	allow(dummy_class).to receive(:static_content_find_by_id).and_return(nil)
    allow(dummy_class).to receive(:documentation_work_title_prefix).and_return("abc")
    allow(::ActiveFedora::SolrService).to receive(:query).and_return([test_file_set])
    allow(dummy_class).to receive(:static_content_find_by_id).and_return("content")        

    dc = dummy_class.static_content_find_by_title( title: "abTitle", id: "abcxyz", solr_query: "")
    expect(dc).to eq("content")
  end

  it 'returns conent by collection title' do 
    allow(dummy_class).to receive(:static_content_find_by_title).and_return("content")                            

    dc = dummy_class.static_content_find_collection_by_title(title: "TestTitle")
    expect(dc).to eq("content")
  end

  it 'return content by work title' do    
    allow(dummy_class).to receive(:static_content_find_by_title).and_return("content")

    dc = dummy_class.static_content_find_work_by_title(title: "TestTitle", id: "abc")
    expect(dc).to eq("content")
  end

  it 'returns file set conent' do  
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil)  
    allow(dummy_class).to receive(:static_content_find_work_by_title).and_return(test_work)
    allow(dummy_class).to receive(:static_content_work_file_set_find_by_title).and_return(test_file_set)
    allow(dummy_class).to receive(:static_content_send_file).and_return("content")
                          
    dc = dummy_class.static_content_for(work_title: "title", file_set_title: "filetitle", path: "/data")
    expect(dc).to eq("content")
  end

  it 'returns static content for read file' do        
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil)
    allow(dummy_class).to receive(:static_content_find_work_by_title).and_return(test_work)
    allow(dummy_class).to receive(:static_content_work_file_set_find_by_title).and_return(test_file_set)
    allow(dummy_class).to receive(:static_content_read_file).and_return("content")

    dc = dummy_class.static_content_for_read_file(work_title: "title", file_set_title: "filetitle", path: "/data")
    expect(dc).to eq("content")
  end

  it 'loads menu file' do  
    allow(dummy_class).to receive(:static_content_for_read_file).and_return("content")         

    dc = dummy_class.static_content_load_menu_file(work_title: "title", file_name: "fileName.txt", path: "/data")
    expect(dc).to eq(nil)
    expect(dummy_class.static_content_menu_links).to eq(["content"])
  end

  it 'sets content main' do   
    allow(dummy_class).to receive(:static_content_for).and_return('value')                                 

    dc = dummy_class.static_content_main( params: {:doc => "test", :format => "pdf"} )
    expect(dc).to eq("value")
  end

  it 'returns menu options based on file set description' do
    allow(test_file_set).to receive(:description_file_set).and_return('menu:description')                            
 
    dc = dummy_class.static_content_options_from( file_set: test_file_set, work_title: "title", file_id: "fileId", format: "txt")
    expect(dc).to eq({:file_id=>"fileId", :menu=>"description"})
  end

  it 'returns file read' do 
    allow(dummy_class).to receive(:static_content_read_file_from_source).and_return("red")
    allow(dummy_class).to receive(:static_content_find_by_id).and_return(test_file_set)  
    allow(test_file_set).to receive(:files_to_file).and_return(test_file) 
    allow(test_uri).to receive(:value).and_return("uri_value") 
 
    dc = dummy_class.static_content_read_file( file_set: test_file_set, id: "abc" )
    expect(dc).to eq("red")
  end

  it 'return true for appropriate mime type' do                             
    dc = dummy_class.static_content_render?( mime_type: "text/html")
    expect(dc).to eq(true)
  end

  it 'returns content msg sent' do 
    allow(dummy_class).to receive(:static_content_send_file).and_return('msg')                            

    dc = dummy_class.static_content_send( file_set: nil, format: "text", path: "/data", options: {} )
    expect(dc).to eq("msg")
  end

  it 'returns content msg sent' do 
    allow(dummy_class).to receive(:static_content_find_by_id).and_return('test_file_set')  
    allow(test_file_set).to receive(:files_to_file).and_return(test_file) 
    allow(test_file).to receive(:mime_type).and_return("text/html") 
    allow(test_uri).to receive(:value).and_return("uri_value")                         

    dc = dummy_class.static_content_send_file( file_set: test_file_set, id: "abc", format: "text", path: "/data", options: {} )
    expect(dc).to eq("done")
  end

  it 'returs read file from uri' do     
    allow(dummy_class).to receive(:static_content_read_file_from_source).and_return("%red")   
    allow(::Deepblue::InterpolationHelper).to receive(:new_interporlation_values).and_return("test")
    allow(::Deepblue::InterpolationHelper).to receive(:interpolate).and_return("new_test")

    dc = dummy_class.static_read_text_from( uri: "uri_value")
    expect(dc).to eq("new_test")
  end

  it 'returns five' do                            
    dc = dummy_class.static_content_send_msg( "msg" )
    expect(dc).to eq("done")
  end

  it 'returns file name and sets content menu' do                            
    dc = dummy_class.static_content_set_menu( value: "file.html.erb", work_title: "work_title", file_id: "fileid", format: "txt")
    expect(dc).to eq("file")
  end

  it 'set the layout for the sidebar' do                   
    dc = dummy_class.static_content_sidebar( {:doc=> "doc", :layout => "layout"} )
    expect(dc).to eq("")
  end

  it 'does something' do
    dc = dummy_class.static_content_title
    expect(dc).to_not eq("")
  end

  it 'return file set based on title' do   
    allow(dummy_class).to receive(:work_view_content_enable_cache).and_return(nil) 
    allow(test_work).to receive(:file_sets).and_return([test_file_set])                              

    dc = dummy_class.static_content_work_file_set_find_by_title( work: test_work, work_title: "title", file_set_title: "fileName", path: "/data")
    expect(dc).to eq(test_file_set)
  end

  it 'enable content cache from class method' do                                
    dc = dummy_class.work_view_content_enable_cache
    expect(dc).to eq("cacheid")
  end

  it 'enable content cache from instance object' do 
    dc = Deepblue::StaticContentControllerBehavior.work_view_content_enable_cache
    expect(dc).to eq("cacheid")
  end
end