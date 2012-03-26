require "rubygems"
require "bundler/setup"
require "sinatra"
require "data_mapper"
require "net/http"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/wee-mail.db")

class Printer
  include DataMapper::Resource
  property :id, Serial
  property :url, String
  property :nickname, String

  has n, :messages
end

class Message
  include DataMapper::Resource
  property :id, Serial
  property :from, String
  property :sent_at, DateTime
  property :body, Text

  belongs_to :printer
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
Printer.auto_upgrade!
Message.auto_upgrade!

helpers do
  def send_message(printer, message_attributes)
    message = printer.messages.create(message_attributes)
    printer_url = URI.parse(printer.url)
    message_url = url("/messages/#{message.id}")
    Net::HTTP.post_form(printer_url, url: message_url)
    message
  end
end

get "/" do
  erb :index
end

get "/register" do
  p url("/messages")
  erb :register
end

post "/register" do
  @printer = Printer.create(params[:printer])
  erb :registered
end

get "/send/:nickname" do
  erb :send
end

post "/send/:nickname" do
  printer = Printer.first(nickname: params[:nickname])
  @message = send_message(printer, params[:message].merge(sent_at: Time.now))
  erb :sent
end

get "/messages/:id" do
  @message = Message.first(id: params[:id])
  erb :message
end