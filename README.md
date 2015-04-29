# Aliyun::OSS

Aliyun::OSS is a Ruby library for Aliyun's Simple Storage Service's REST API (http://www.aliyun.com/product/oss).
Full documentation of the currently supported API can be found at http://www.aliyun.com/product/oss#resources.

## Getting started

To get started you need to require 'aliyun/oss':

```bash
% irb -rubygems
irb(main):001:0> require 'aliyun/oss'
# => true
```

The Aliyun::OSS library ships with an interactive shell called `oss`. From within it, you have access to all the operations the library exposes from the command line.

```bash
% oss
>> Version
```

Before you can do anything, you must establish a connection using Base.establish_connection!.  A basic connection would look something like this:

```ruby
Aliyun::OSS::Base.establish_connection!(
  :access_key_id     => 'abc', 
  :secret_access_key => '123'
)
```

The minimum connection options that you must specify are your access key id and your secret access key.

(If you don't already have your access keys, all you need to sign up for the OSS service is an account at Aliyun. You can sign up for OSS and get access keys by visiting [http://aliyun.aliyun.com/oss](http://aliyun.aliyun.com/oss).)

For convenience, if you set two special environment variables with the value of your access keys, the console will automatically create a default connection for you. For example:

```bash
% cat .oss_keys
export OSS_ACCESS_KEY_ID='abcdefghijklmnop'
export OSS_SECRET_ACCESS_KEY='1234567891012345'
```

Then load it in your shell's rc file.

```bash
% cat .zshrc
if [[ -f "$HOME/.oss_keys" ]]; then
  source "$HOME/.oss_keys";
fi
```

See more connection details at Aliyun::OSS::Connection::Management::ClassMethods.


## Aliyun::OSS Basics

### The service, buckets and objects

The three main concepts of OSS are the service, buckets and objects. 

### The service

The service lets you find out general information about your account, like what buckets you have. 

```ruby
Service.buckets
# => []
````

 
### Buckets

Buckets are containers for objects (the files you store on OSS). To create a new bucket you just specify its name.

```ruby
# Pick a unique name, or else you'll get an error 
# if the name is already taken.
Bucket.create('jukebox')
```

Bucket names must be unique across the entire OSS system, sort of like domain names across the internet. If you try
to create a bucket with a name that is already taken, you will get an error.

Assuming the name you chose isn't already taken, your new bucket will now appear in the bucket list:

```ruby
Service.buckets
# => [#<Aliyun::OSS::Bucket @attributes={"name"=>"jukebox"}>]
```

Once you have succesfully created a bucket you can fetch it by name using Bucket.find.

```ruby
music_bucket = Bucket.find('jukebox')
```

The bucket that is returned will contain a listing of all the objects in the bucket.

```ruby
music_bucket.objects.size
# => 0
```

If all you are interested in is the objects of the bucket, you can get to them directly using Bucket.objects.

```ruby
Bucket.objects('jukebox').size
# => 0
```

By default all objects will be returned, though there are several options you can use to limit what is returned, such as
specifying that only objects whose name is after a certain place in the alphabet be returned, and etc. Details about these options can
be found in the documentation for Bucket.find.

To add an object to a bucket you specify the name of the object, its value, and the bucket to put it in.

```ruby
file = 'black-flowers.mp3'
OSSObject.store(file, open(file), 'jukebox')
```

You'll see your file has been added to it:

```ruby
music_bucket.objects
# => [#<Aliyun::OSS::OSSObject '/jukebox/black-flowers.mp3'>]
```

You can treat your bucket like a hash and access objects by name:

```ruby
jukebox['black-flowers.mp3']
# => #<Aliyun::OSS::OSSObject '/jukebox/black-flowers.mp3'>
```

In the event that you want to delete a bucket, you can use Bucket.delete.

```ruby
Bucket.delete('jukebox')
```

Keep in mind, like unix directories, you can not delete a bucket unless it is empty. Trying to delete a bucket
that contains objects will raise a BucketNotEmpty exception.

Passing the :force => true option to delete will take care of deleting all the bucket's objects for you.

```ruby
Bucket.delete('photos', :force => true)
# => true
```


#### Objects

OSSObjects represent the data you store on OSS. They have a key (their name) and a value (their data). All objects belong to a
bucket.

You can store an object on OSS by specifying a key, its data and the name of the bucket you want to put it in:

```ruby
OSSObject.store('me.jpg', open('headshot.jpg'), 'photos')
```

The content type of the object will be inferred by its extension. If the appropriate content type can not be inferred, OSS defaults
to `binary/octet-stream`.

If you want to override this, you can explicitly indicate what content type the object should have with the `:content_type` option:

```ruby
file = 'black-flowers.m4a'
OSSObject.store(file, open(file), 'jukebox', :content_type => 'audio/mp4a-latm')
```

You can read more about storing files on OSS in the documentation for OSSObject.store.

If you just want to fetch an object you've stored on OSS, you just specify its name and its bucket:

```ruby
picture = OSSObject.find('headshot.jpg', 'photos')
```

N.B. The actual data for the file is not downloaded in both the example where the file appeared in the bucket and when fetched directly. 
You get the data for the file like this:

```ruby
picture.value
```

You can fetch just the object's data directly:

```ruby
OSSObject.value 'headshot.jpg', 'photos'
```

Or stream it by passing a block to `stream`:

```ruby
open('song.mp3', 'w') do |file|
  OSSObject.stream('song.mp3', 'jukebox') do |chunk|
    file.write chunk
  end
end
```

The data of the file, once download, is cached, so subsequent calls to `value` won't redownload the file unless you 
tell the object to reload its `value`:

```ruby`
# Redownloads the file's data
song.value(:reload) 
```

Other functionality includes:

```ruby
# Check if an object exists?
OSSObject.exists? 'headshot.jpg', 'photos'

# Copying an object
OSSObject.copy 'headshot.jpg', 'headshot2.jpg', 'photos'

# Renaming an object
OSSObject.rename 'headshot.jpg', 'portrait.jpg', 'photos'

# Deleting an object
OSSObject.delete 'headshot.jpg', 'photos'
```

#### More about objects and their metadata

You can find out the content type of your object with the `content_type` method:

```ruby
song.content_type
# => "audio/mpeg"
```

You can change the content type as well if you like:

```ruby
song.content_type = 'application/pdf'
song.store
```

(Keep in mind that due to limitiations in OSS's exposed API, the only way to change things like the content_type
is to PUT the object onto OSS again. In the case of large files, this will result in fully re-uploading the file.)

A bevie of information about an object can be had using the `about` method:

  pp song.about
  {"last-modified"    => "Sat, 28 Oct 2006 21:29:26 GMT",
   "content-type"     => "binary/octet-stream",
   "etag"             => "\"dc629038ffc674bee6f62eb64ff3a\"",
   "date"             => "Sat, 28 Oct 2006 21:30:41 GMT",
   "x-amz-request-id" => "B7BC68F55495B1C8",
   "server"           => "AliyunOSS",
   "content-length"   => "3418766"}

You can get and set metadata for an object:

  song.metadata
  # => {}
  song.metadata[:album] = "A River Ain't Too Much To Love"
  # => "A River Ain't Too Much To Love"
  song.metadata[:released] = 2005
  pp song.metadata
  {"x-amz-meta-released" => 2005, 
    "x-amz-meta-album"   => "A River Ain't Too Much To Love"}
  song.store

That metadata will be saved in OSS and is hence forth available from that object:

  song = OSSObject.find('black-flowers.mp3', 'jukebox')
  pp song.metadata
  {"x-amz-meta-released" => "2005", 
    "x-amz-meta-album"   => "A River Ain't Too Much To Love"}
  song.metadata[:released]
  # => "2005"
  song.metadata[:released] = 2006
  pp song.metadata
  {"x-amz-meta-released" => 2006, 
   "x-amz-meta-album"    => "A River Ain't Too Much To Love"}


#### Streaming uploads

When storing an object on the OSS servers using OSSObject.store, the `data` argument can be a string or an I/O stream. 
If `data` is an I/O stream it will be read in segments and written to the socket incrementally. This approach 
may be desirable for very large files so they are not read into memory all at once.

```ruby
# Non streamed upload
OSSObject.store('greeting.txt', 'hello world!', 'marcel')

# Streamed upload
OSSObject.store('roots.mpeg', open('roots.mpeg'), 'marcel')
````


## Setting the current bucket

#### Scoping operations to a specific bucket

If you plan on always using a specific bucket for certain files, you can skip always having to specify the bucket by creating 
a subclass of Bucket or OSSObject and telling it what bucket to use:

```ruby
class JukeBoxSong < Aliyun::OSS::OSSObject
  set_current_bucket_to 'jukebox'
end
```

For all methods that take a bucket name as an argument, the current bucket will be used if the bucket name argument is omitted.

```ruby
other_song = 'baby-please-come-home.mp3'
JukeBoxSong.store(other_song, open(other_song))
```

This time we didn't have to explicitly pass in the bucket name, as the JukeBoxSong class knows that it will
always use the 'jukebox' bucket. 

"Astute readers", as they say, may have noticed that we used the third parameter to pass in the content type,
rather than the fourth parameter as we had the last time we created an object. If the bucket can be inferred, or
is explicitly set, as we've done in the JukeBoxSong class, then the third argument can be used to pass in
options.

Now all operations that would have required a bucket name no longer do.

```ruby
other_song = JukeBoxSong.find('baby-please-come-home.mp3')
```


## Access control

#### Using canned access control policies

By default buckets are private. This means that only the owner has access rights to the bucket and its objects. 
Objects in that bucket inherit the permission of the bucket unless otherwise specified. When an object is private, the owner can 
generate a signed url that exposes the object to anyone who has that url. Alternatively, buckets and objects can be given other 
access levels. Several canned access levels are defined:

* `:private` - Owner gets FULL_CONTROL. No one else has any access rights. This is the default.
* `:public_read` - Owner gets FULL_CONTROL and the anonymous principal is granted READ access. If this policy is used on an object, it can be read from a browser with no authentication.
* `:public_read_write` - Owner gets FULL_CONTROL, the anonymous principal is granted READ and WRITE access. This is a useful policy to apply to a bucket, if you intend for any anonymous user to PUT objects into the bucket.
* `:authenticated_read` - Owner gets FULL_CONTROL, and any principal authenticated as a registered Aliyun OSS user is granted READ access.

You can set a canned access level when you create a bucket or an object by using the `:access` option:

```ruby
OSSObject.store('kiss.jpg', data, 'marcel', :access => :public_read)
```

Since the image we created is publicly readable, we can access it directly from a browser by going to the corresponding bucket name 
and specifying the object's key without a special authenticated url:

 http://oss.aliyuncs.com/marcel/kiss.jpg


#### Accessing private objects from a browser

All private objects are accessible via an authenticated GET request to the OSS servers. You can generate an 
authenticated url for an object like this:

```ruby
OSSObject.url_for('beluga_baby.jpg', 'marcel_molina')
```

By default authenticated urls expire 5 minutes after they were generated.

Expiration options can be specified either with an absolute time since the epoch with the `:expires` options,
or with a number of seconds relative to now with the `:expires_in` options:

```ruby
# Absolute expiration date 
# (Expires January 18th, 2038)
doomsday = Time.mktime(2038, 1, 18).to_i
OSSObject.url_for('beluga_baby.jpg', 
                 'marcel', 
                 :expires => doomsday)

# Expiration relative to now specified in seconds 
# (Expires in 3 hours)
OSSObject.url_for('beluga_baby.jpg', 
                 'marcel', 
                 :expires_in => 60 * 60 * 3)
```

You can specify whether the url should go over SSL with the `:use_ssl` option:

```ruby
# Url will use https protocol
OSSObject.url_for('beluga_baby.jpg', 
                 'marcel', 
                 :use_ssl => true)
```

By default, the ssl settings for the current connection will be used.

If you have an object handy, you can use its `url` method with the same objects:

```ruby
song.url(:expires_in => 30)
```

To get an unauthenticated url for the object, such as in the case
when the object is publicly readable, pass the
`:authenticated` option with a value of `false`.

```ruby
OSSObject.url_for('beluga_baby.jpg',
                 'marcel',
                 :authenticated => false)
# => http://oss.aliyuncs.com/marcel/beluga_baby.jpg
```


## Logging

#### Tracking requests made on a bucket

A bucket can be set to log the requests made on it. By default logging is turned off. You can check if a bucket has logging enabled:

```ruby
Bucket.logging_enabled_for? 'jukebox'
# => false
```

Enabling it is easy:

```ruby
Bucket.enable_logging_for('jukebox')
```

Unless you specify otherwise, logs will be written to the bucket you want to log. The logs are just like any other object. By default they will start with the prefix 'log-'. You can customize what bucket you want the logs to be delivered to, as well as customize what the log objects' key is prefixed with by setting the `target_bucket` and `target_prefix` option:

```ruby
Bucket.enable_logging_for('jukebox', 'target_bucket' => 'jukebox-logs')
```

Now instead of logging right into the jukebox bucket, the logs will go into the bucket called jukebox-logs.

Once logs have accumulated, you can access them using the `logs` method:

```ruby
pp Bucket.logs('jukebox')
[#<Aliyun::OSS::Logging::Log '/jukebox-logs/log-2006-11-14-07-15-24-2061C35880A310A1'>,
 #<Aliyun::OSS::Logging::Log '/jukebox-logs/log-2006-11-14-08-15-27-D8EEF536EC09E6B3'>,
 #<Aliyun::OSS::Logging::Log '/jukebox-logs/log-2006-11-14-08-15-29-355812B2B15BD789'>]
```

Each log has a `lines` method that gives you information about each request in that log. All the fields are available 
as named methods. More information is available in Logging::Log::Line.

```ruby
logs = Bucket.logs('jukebox')
log  = logs.first
line = log.lines.first
line.operation
# => 'REST.GET.LOGGING_STATUS'
line.request_uri
# => 'GET /jukebox?logging HTTP/1.1'
line.remote_ip
# => "67.165.183.125"
```

Disabling logging is just as simple as enabling it:

```ruby
Bucket.disable_logging_for('jukebox')
```


## Errors

#### When things go wrong

Anything you do that makes a request to OSS could result in an error. If it does, the Aliyun::OSS library will raise an exception 
specific to the error. All exception that are raised as a result of a request returning an error response inherit from the 
ResponseError exception. So should you choose to rescue any such exception, you can simple rescue ResponseError. 

Say you go to delete a bucket, but the bucket turns out to not be empty. This results in a BucketNotEmpty error (one of the many 
errors listed at http://docs.aliyunwebservices.com/AliyunOSS/2006-03-01/ErrorCodeList.html):

```ruby
begin
  Bucket.delete('jukebox')
rescue ResponseError => error
  # ...
end
```

Once you've captured the exception, you can extract the error message from OSS, as well as the full error response, which includes 
things like the HTTP response code:

```ruby`
error
# => #<Aliyun::OSS::BucketNotEmpty The bucket you tried to delete is not empty>
error.message
# => "The bucket you tried to delete is not empty"
error.response.code
# => 409
```

You could use this information to redisplay the error in a way you see fit, or just to log the error and continue on.


#### Accessing the last request's response

Sometimes methods that make requests to the OSS servers return some object, like a Bucket or an OSSObject. 
Othertimes they return just `true`. Other times they raise an exception that you may want to rescue. Despite all these 
possible outcomes, every method that makes a request stores its response object for you in Service.response. You can always 
get to the last request's response via Service.response.

```ruby
objects = Bucket.objects('jukebox')
Service.response.success?
# => true
```

This is also useful when an error exception is raised in the console which you weren't expecting. You can 
root around in the response to get more details of what might have gone wrong.

  
