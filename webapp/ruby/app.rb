require 'digest/sha1'
require 'mysql2'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'dalli'
require 'pry'


class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  set :database, {adapter: 'mysql2',
                  database: 'isubata',
                  pool: 16,
                  reconnect: true,
                  host: ENV['ISUBATA_DB_HOST'],
                  username: ENV['ISUBATA_DB_USER'],
                  password: ENV['ISUBATA_DB_PASSWORD']}
  ActiveRecord::Base.logger = nil
  class Channel < ActiveRecord::Base
    has_many :havereads
    self.table_name = 'channel'
  end
  class User < ActiveRecord::Base
    has_many :messages
    has_many :havereads
    self.table_name = 'user'
  end
  class Haveread < ActiveRecord::Base
    self.table_name = 'haveread'
  end
  class Message < ActiveRecord::Base
    belongs_to :user
    self.table_name = 'message'
  end

  configure do
    set :session_secret, 'tonymoris'
    set :public_folder, File.expand_path('../../public', __FILE__)
    set :avatar_max_size, 1 * 1024 * 1024

    enable :sessions
  end

  # Init: write images from DB. TODO: convert to rake task.
  # class Image < ActiveRecord::Base
  #   self.table_name = 'image'
  # end
  # Image.find_each(batch_size: 1){|i| File.write([settings.public_folder, 'icons', i.name].join('/'), i.data) }

  helpers do
    def user
      return @_user unless @_user.nil?

      user_id = session[:user_id]
      return nil if user_id.nil?

      @_user = db_get_user(user_id)
      if @_user.nil?
        params[:user_id] = nil
        return nil
      end

      @_user
    end
  end

  get '/initialize' do
    User.where('id > 1000').destroy_all
    Channel.where('id > 10').destroy_all
    Message.where('id > 10000').destroy_all
    Haveread.destroy_all
    204
  end

  get '/' do
    if session.has_key?(:user_id)
      return redirect '/channel/1', 303
    end
    erb :index
  end

  get '/channel/:channel_id' do
    if user.nil?
      return redirect '/login', 303
    end

    @channel_id = params[:channel_id].to_i
    @channels, @description = get_channel_list_info(@channel_id)
    erb :channel
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    name = params[:name]
    pw = params[:password]
    if name.nil? || name.empty? || pw.nil? || pw.empty?
      return 400
    end
    begin
      user_id = register(name, pw)
    rescue => e
      return 409 if e.class == ActiveRecord::RecordNotUnique
      raise e
    end
    session[:user_id] = user_id
    redirect '/', 303
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    u = User.find_by(name: params[:name])
    if u.nil? || u['password'] != Digest::SHA1.hexdigest(u['salt'] + params[:password])
      return 403
    end
    session[:user_id] = u['id']
    redirect '/', 303
  end

  get '/logout' do
    session[:user_id] = nil
    redirect '/', 303
  end

  post '/message' do
    user_id = session[:user_id]
    message = params[:message]
    channel_id = params[:channel_id]
    if user_id.nil? || message.nil? || channel_id.nil? || user.nil?
      return 403
    end
    Message.create(user_id: user_id, content: message, channel_id: channel_id, created_at: Time.now)
    204
  end

  get '/message' do
    user_id = session[:user_id]
    if user_id.nil?
      return 403
    end

    channel_id = params[:channel_id].to_i
    last_message_id = params[:last_message_id].to_i
    messages = Message.where('id > ?', last_message_id).where('channel_id = ?', channel_id).order('id desc').limit(100).includes(:user)
    response = messages.map do |message|
      {'id' => message.id,
       'user' => message.user.as_json(only: [:name, :display_name, :avatar_icon]),
       'date' => message.created_at.strftime("%Y/%m/%d %H:%M:%S"),
       'content' => message.content
      }
    end
    response.reverse!

    max_message_id = messages.empty? ? 0 : messages.map { |row| row['id'] }.max
    h = Haveread.find_by(user_id: user_id, channel_id: channel_id)
    if h.nil?
      t = Time.now
      Haveread.create!(user_id: user_id, channel_id: channel_id, message_id: max_message_id, updated_at: t, created_at: t)
    else
      h.update_attributes(message_id: max_message_id, updated_at: Time.now)
    end

    content_type :json
    response.to_json
  end

  get '/fetch' do
    user_id = session[:user_id]
    if user_id.nil?
      return 403
    end

    channels = Channel.joins(:havereads).where('haveread.user_id = ?', user_id).select(:id)

    res = channels.map do |c|
      r = {}
      r['channel_id'] = c.id
      r['unread'] = if c.havereads.blank?
        Message.where('channel_id = ?', c.id).count
      else
        Message.where('channel_id = ?', c.id).where('? < id', c.havereads.first.message_id).count
      end
      r
    end

    content_type :json
    res.to_json
  end

  get '/history/:channel_id' do
    if user.nil?
      return redirect '/login', 303
    end

    @channel_id = params[:channel_id].to_i

    @page = params[:page]
    if @page.nil?
      @page = '1'
    end
    if @page !~ /\A\d+\Z/ || @page == '0'
      return 400
    end
    @page = @page.to_i

    n = 20
    messages = Message.where(channel_id: @channel_id).order(id: :desc).limit(n).offset((@page - 1) * n).includes(:user)
    @messages = messages.map do |message|
      r = {}
      r['id'] = message.id
      r['user'] = message.user.as_json(only: [:name, :display_name, :avatar_icon])
      r['date'] = message.created_at.strftime("%Y/%m/%d %H:%M:%S")
      r['content'] = message.content
      r
    end.reverse

    cnt = Message.where(channel_id: @channel_id).count.to_f
    @max_page = cnt == 0 ? 1 :(cnt / n).ceil

    return 400 if @page > @max_page

    @channels, @description = get_channel_list_info(@channel_id)
    erb :history
  end

  get '/profile/:user_name' do
    if user.nil?
      return redirect '/login', 303
    end

    @user = User.find_by(name: params[:user_name])

    if @user.nil?
      return 404
    end

    @channels = get_channel_list
    @self_profile = user['id'] == @user['id']
    erb :profile
  end

  get '/add_channel' do
    if user.nil?
      return redirect '/login', 303
    end

    @channels = get_channel_list
    erb :add_channel
  end

  post '/add_channel' do
    if user.nil?
      return redirect '/login', 303
    end

    name = params[:name]
    description = params[:description]
    if name.nil? || description.nil?
      return 400
    end
    t = Time.now
    channel_id = Channel.create(name: name, description: description, updated_at: t, created_at: t).id
    redirect "/channel/#{channel_id}", 303
  end

  post '/profile' do
    if user.nil?
      return redirect '/login', 303
    end

    display_name = params[:display_name]
    avatar_name = nil
    avatar_data = nil

    file = params[:avatar_icon]
    unless file.nil?
      filename = file[:filename]
      if !filename.nil? && !filename.empty?
        ext = filename.include?('.') ? File.extname(filename) : ''
        unless ['.jpg', '.jpeg', '.png', '.gif'].include?(ext)
          return 400
        end

        if settings.avatar_max_size < file[:tempfile].size
          return 400
        end

        data = file[:tempfile].read
        digest = Digest::SHA1.hexdigest(data)

        avatar_name = digest + ext
        avatar_data = data
      end
    end

    target_user = User.find(user['id'])

    if !avatar_name.nil? && !avatar_data.nil?
      memcached.set(avatar_name, avatar_data, (30*24*30*30))
      target_user.avatar_icon = avatar_name
    end

    if !display_name.nil? || !display_name.empty?
      target_user.display_name = display_name
    end

    target_user.save if target_user.changed?

    redirect '/', 303
  end

  private

  def memcached
    return @memcached if defined?(@memcached)
    @memcached = Dalli::Client.new(ENV['ISUBATA_DB_HOST'], namespace: 'isubata')
  end

  def db_get_user(user_id)
    User.find(user_id)
  end

  def random_string(n)
    Array.new(20).map { (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).sample }.join
  end

  def register(user, password)
    salt = random_string(20)
    pass_digest = Digest::SHA1.hexdigest(salt + password)
    u = User.create(name: user, salt: salt, password: pass_digest, display_name: user, avatar_icon: 'default.png', created_at: Time.now)
    u.id
  end

  def get_channel_list
    Channel.order(:id)
  end

  def get_channel_list_info(focus_channel_id = nil)
    channels = Channel.order(:id)
    description = ''
    channels.each do |channel|
      if channel['id'] == focus_channel_id
        description = channel['description']
        break
      end
    end
    [channels, description]
  end
end
