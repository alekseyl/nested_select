# WIP disclaimer
The gem is under active development now. 
Use in prod with caution only if you are properly covered by your CI. 
Read **Safety** and **Limitations** sections before.

# Nested select -- 7 times faster and 33 times less RAM on preloading relations with heavy columns!
nested_select allows the partial selection of the relations attributes during preloading process, leading to less RAM and CPU usage.
Here is a benchmark output for a [gist I've created](https://gist.github.com/alekseyl/5d08782808a29df6813f16965f70228a) to emulate real-life example: displaying a course with its structure.

Given: 
- Models are Course, Topic, Lesson. 
- Their relations has a following structure: course has_many topics, each topic has_many lessons. 
- To display a single course you need its structure, minimum data needed: topic and lessons titles and ordering.

**Single course**, a real prod set of data used by current UI (~ x33 times less RAM):

```
irb(main):216:0>compare_nested_select(ids, 1, silence_ar_logger_for_memory_profiling: false)

------- CPU comparison, for root_collection_size: 1 ----                                                           
       user     system      total        real                                                                      
nested_select  0.096008   0.002876   0.098884 (  0.466985)                                                         
simple includes  0.209188   0.058340   0.267528 (  0.903893)                                                       
                                                                                                                   
----------------- Memory comparison, for root_collection_size: 1 ---------                                         
# partial selection
D, [2025-01-12T19:08:36.163282 #503] DEBUG -- :   Topic Load (4.1ms)  SELECT "topics"."id", "topics"."position", "topics"."title", "topics"."course_id" FROM "topics" WHERE "topics"."deleted_at" IS NULL AND "topics"."course_id" = $1  [["course_id", 1624]]                                                                 
D, [2025-01-12T19:08:36.168803 #503] DEBUG -- :   Lesson Load (3.9ms)  SELECT "lessons"."id", "lessons"."title", "lessons"."topic_id", "lessons"."position", "lessons"."topic_id" FROM "lessons" WHERE "lessons"."deleted_at" IS NULL AND "lessons"."topic_id" = $1  [["topic_id", 7297]]                                      
# selects in full 
D, [2025-01-12T19:08:37.220379 #503] DEBUG -- :   Topic Load (4.2ms)  SELECT "topics"."id", "topics"."position", "topics"."title", "topics"."course_id" FROM "topics" WHERE "topics"."deleted_at" IS NULL AND "topics"."course_id" = $1  [["course_id", 1624]]                                                                 
D, [2025-01-12T19:08:37.247484 #503] DEBUG -- :   Lesson Load (25.7ms)  SELECT "lessons".* FROM "lessons" WHERE "lessons"."deleted_at" IS NULL AND "lessons"."topic_id" = $1  [["topic_id", 7297]]

------ Nested Select memory consumption for root_collection_size: 1 ------                                         
Total allocated: 80.84 kB (972 objects)
Total retained:  34.67 kB (288 objects)

------ Full preloading memory consumption for root_collection_size: 1 ----
Total allocated: 1.21 MB (1105 objects)
Total retained:  1.16 MB (432 objects)
RAM ratio improvements x33.54678126442086 on retain objects
RAM ratio improvements x15.002820281285949 on total_allocated objects
```

**100 courses**, this is kinda a synthetic example (there is no UI for multiple courses display with their structure) 
on the real prod data, but the bigger than needed collection (x7 faster):

```
irb(main):280:0> compare_nested_select(ids, 100)

------- CPU comparison, for root_collection_size: 100 ----
                    user     system      total        real           
nested_select    1.571095   0.021778   1.592873 (  2.263369)
simple includes  5.374909   1.704284   7.079193 ( 15.488579) 
                                                        
----------------- Memory comparison, for root_collection_size: 100 ---------
------ Nested Select memory consumption for root_collection_size: 100 ------

Total allocated: 2.79 MB (30702 objects)                
Total retained:  2.05 MB (16431 objects)                

------ Full preloading memory consumption for root_collection_size: 100 ----

Total allocated: 33.05 MB (38332 objects)               
Total retained:  32.00 MB (24057 objects)               
RAM ratio improvements x15.57707431190517 on retain objects
RAM ratio improvements x11.836000856510193 on total_allocated objects
```

Despite this little click bait it's pretty obvious that it might not be even the biggest numbers, 
if you have heavy relations instantiation for heavy views or reports generation, 
and you want it to be less demanding in RAM and CPU -- you should try nested_select

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add nested_select

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install nested_select

## Usage

### Specify which attributes to load in preloading models   
Assume you have a relation users <- profile, and you want to preview users in a paginated feed, 
and you need only :photo_url attribute of a profile, with nested_select you can do it like this:  

```ruby
class User
  has_one :profile
end

class Profile
  belongs_to :user
end

# this will preload profile with exact attributes: 
# :id -- since its a primary key, 
# :user_id -- since its a foreign_key
# and the :photo_url as requested
User.includes(:profile).select(profile: :photo_url).limit(10)
```

### Partial through relations preloading
Whenever you are using through relations between models rails will fully load all intermediate objects under the hood,
that is definitely wastes lots of RAM, CPU including those on the DB side. 
You can limit through objects only to relation columns. 
Ex:

```ruby
class User
  has_one :user_profile, inverse_of: :user
  has_many :avatars, through: :user_profile, inverse_of: :user
end

  # pay attention user_profile relation, wasn't included explicitly, 
  # but still rails needed to be preloaded to match and preload avatars here
  user = User.includes(:avatars)
             .select(avatars: [:img_url, { user_profile: [:zip_code] }]).first
  
  # Now user - loaded fully
  # avatars - foreign and primary keys needed to establish relations + img_url
  # user_profile - foreign and primary keys + zip_code
```
**REM:** Through preloading happens in reverse, so to nest their selection 
you must start from the latest, in this case avatar, and go to the previous ones in this case its a user_profile

If you want intermediate models to be completely skinny, you should select like this:

```ruby
class User
  has_one :user_profile, inverse_of: :user
  has_many :avatars, through: :user_profile, inverse_of: :user
  has_many :through_avatar_images, through: :avatars, class_name: :Image, source: :images
end

  # only through_avatar_images is matter here, and we want everything 
  user = User.includes(:through_avatar_images)
             .select(through_avatar_images: ["images.*", avatars: [user_profile: [:id]]]).first
  
  # through_avatar_images -- loaded in full
  # avatars, user_profile -- only relations columns id, user_profile_id e.t.c
```
**REM** As for version 0.4.0 for the earliest relation in a through chain you need to select something, 
otherwise nested_select will select everything ))

# Safety
How safe is the partial model loading? Earlier version of rails and activerecord would return nil in the case, 
when attribute wasn't selected from a DB, but rails 6 started to raise a ActiveModel::MissingAttributeError. 
So the major problem is already solved -- your code will not operate based on falsy blank values, it will raise an exception. 

But if you are working with attributes directly ( which you should not btw ), you will see nil, without any exception. 
Using as_json on such models will also deliver json without exception and without skipped attributes. 

## Partial selection in multiple preloading branches
If you are doing some strange or narrow cases whenever you preloading same objects via different preloading branches, 
including the most common case through relations, which rails preloads in full, then you must be very accurate 
with nested selection, cause rails loads and attach associations only once, if it was partial
than you might get yourself into trouble. BUT nested_select will check and raise an exception 
if you are trying to re-instantiate with a different set of attributes. Ex:

```
ActiveModel::MissingAttributeError: Reflection 'avatars' already loaded with a different set of basic attributes.
expected: ["img_url", "user_profile_id", "id"], already loaded with: ["created_at", "user_profile_id", "id"]
Hint: ensure that you are using same set of attributes for entrance of same relation
      on nesting selection tree including reverse through relations
```

# Limitations

## belongs_to foreign keys limitations 
Rails preloading happens from loaded records to their reflections step by step. 
That's makes it pretty easy to include foreign keys for has_* relations, and very hard for belongs_to, 
to work this out you need to analyze includes based on the already loaded records, analyze and traverse their relations.
This needs a lot of monkey patching, and for now I decided not to go this way.
That means in case when nesting selects based on belongs_to reflections, 
you'll need to select their foreign keys **EXPLICITLY!** 

## will not work with ar_lazy_preload
Right now it will not work with ar_lazy_preload gem. nested_select relies on the includes_values definition 
of a relation. If you are doing it in a lazy way, there weren't any explicit includes, that means it will not extract any nested selection.

```ruby
class Avatar < ApplicationRecord
  belongs_to user
  has_one :image
end

class Image < ApplicationRecord
  belongs_to :avatar
end

Image.includes(avatar: :user).select(avatar: [:size, { user: [:email] }]).load # <--- will raise a Missing Attribute exception 

#> ActiveModel::MissingAttributeError: Parent reflection avatar was missing foreign key user_id in nested selection
#> while trying to preload belongs_to reflection named user.
#> Hint: didn't you forgot to add user_id inside [:id, :size]?

Image.includes(avatar: :user).select(avatar: [:size, :user_id, { user: [:email] }]).load
```

## Testing

```bash
docker compose run test 
```

## TODO
- [x] Cover all relation combinations and add missing functionality
  - [x] Ensure relations foreign keys are present on the selection
  - [x] Ensure primary key will be added
  - [-] Ensure belongs_to will add a foreign_key column (Too hard to manage :(, its definitely not a low hanging fruit)
- [x] Optimize through relations ( since they loading a whole set of attributes )
- [ ] Separated rails version testing
- [x] Merge multiple nested selections 
- [x] Don't apply any selection if blank ( allows to limit only part of subselection tree)
- [x] Allows to use custom attributes
- [ ] Eager loading? 

## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alekseyl/nested_select. This project is intended to be a safe, 
welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NestedSelect project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).
