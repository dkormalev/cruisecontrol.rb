class ProjectsController < ApplicationController
  
  verify :params => "id", :only => [:show, :build, :code],
         :render => { :text => "Project not specified",
                      :status => 404 }
  verify :params => "path", :only => [:code],
         :render => { :text => "Path not specified",
                      :status => 404 }
  def index
    @projects = Project.all
    
    respond_to do |format|
      format.html
      format.js { render :action => 'index_js' }
      format.rss { render :action => 'index_rss', :layout => false, :format => :xml }
      format.cctray { render :action => 'index_cctray', :layout => false }
    end
  end

  def show
    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    respond_to do |format|
      format.html { redirect_to :controller => "builds", :action => "show", :project => @project }
      format.rss { render :action => 'show_rss', :layout => false }
    end
  end

  def build
    render :text => 'Build requests are not allowed', :status => 403 and return if Configuration.disable_build_now

    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil
    @projects = Project.all

    respond_to { |format| format.js { render :action => 'index_js' } }
  end
  
  def code
    if Configuration.disable_code_browsing
      render :text => "Code browsing disabled" and return
    end

    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project 

    work_path = File.join(@project.path, 'work')
    params[:path].reject! do |elem|
      elem.empty?
    end
    path = File.join(work_path, params[:path])
    if File.expand_path(path).index(File.expand_path(work_path)) != 0
      render :text => 'This file is not part of project', :status => 500 
      return
    end
    @line = params[:line].to_i if params[:line]
    
    if File.directory?(path)
      dir_entries = Dir.entries(path)
      dir_entries -= ['.', '..', '.git', '.svn']
      @curr_path = File.join(params[:path])
      @curr_path += '/' unless @curr_path.empty?
      @parent_path = File.dirname @curr_path
      @parent_path = '' if @parent_path == '.'
      parent_path_full = File.dirname path
      @go_to_parent_allowed = true
      if (@parent_path == '.' and @curr_path.empty?) or 
          parent_path_full.index(File.expand_path(work_path)) != 0
        @go_to_parent_allowed = false
      end
      @dirs = Array.new
      @files = Array.new
      dir_entries.each do |entry|
        if File.directory?(File.join(path, entry))
          @dirs << entry
        else
          @files << entry
        end
      end
      @dirs.sort!
      @files.sort!
      render :action => 'code_dir'
#      render :text => 'Viewing of source directories is not supported yet', :status => 500 
    elsif File.file?(path)
      @content = File.read(path)
      @parent_path = File.dirname(File.join(params[:path]))
      @parent_path = '' if @parent_path == '.'
    else
      render_not_found
    end
  end

end
