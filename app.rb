require "sinatra"
require "sinatra/reloader"# if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"


configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @files = []
  Dir.each_child(data_path) { |filename| @files << filename }
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    content
  when ".md"
    render_markdown(content)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  erb :home
end

get "/new" do
  erb :new
end

post "/new" do
  @file_name = params[:title]
  @file_path = File.join(data_path, @file_name)

  if @file_name == ""
    session[:message] = "A name is required!"
    status 422
    erb :new
  elsif
    File.exist?(@file_path)
    session[:message] = "#{@file_name} already exists!"
    status 422
    erb :new
  else
    File.write(@file_path, "")
    session[:message] = "#{@file_name} has been created!"
    redirect "/"
  end
end

get "/:filename" do
  @file_name = params[:filename]
  @file_path = File.join(data_path, @file_name)

  if File.exist?(@file_path)
    @data = load_file_content(@file_path)
    erb :file
  else
    session[:message] = "#{@file_name} does not exist"
    redirect "/"
  end
end

get "/:filename/edit" do
  @file_name = params[:filename]
  @file_path = File.join(data_path, @file_name)

  if File.exist?(@file_path)
    @data = load_file_content(@file_path)
    erb :edit
  else
    session[:message] = "#{@file_name} does not exist"
    redirect "/"
  end
end

post "/:filename/edit" do
  @file_name = params[:filename]
  @file_path = File.join(data_path, @file_name)

  File.write(@file_path, params[:content])
  session[:message] = "#{@file_name} has been updated."
  redirect "/"
end

post "/:filename/delete" do
  @file_name = params[:filename]
  @file_path = File.join(data_path, @file_name)

  File.delete(@file_path)
  session[:message] = "#{@file_name} has been deleted."
  redirect "/"
end




