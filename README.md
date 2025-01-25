# WIP disclaimer
The gem is under active development now. As of version 0.2.0 you are safe to try in your prod console 
to uncover it's potential, and try in dev/test env. 
Be aware as for 0.2.0 version not all relation foreign keys are extracted from relations, and you might need to specify them exactly!

Use in prod with caution only if you are properly covered by your CI.

# Nested select -- 7 times faster and 33 times less RAM on preloading relations with heavy columns!
nested_select allows to select attributes of relations during preloading process, leading to less RAM and CPU usage.
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

D, [2025-01-12T19:08:36.163282 #503] DEBUG -- :   Topic Load (4.1ms)  SELECT "topics"."id", "topics"."position", "topics"."title", "topics"."course_id" FROM "topics" WHERE "topics"."deleted_at" IS NULL AND "topics"."course_id" = $1  [["course_id", 1624]]                                                                 
D, [2025-01-12T19:08:36.168803 #503] DEBUG -- :   Lesson Load (3.9ms)  SELECT "lessons"."id", "lessons"."title", "lessons"."topic_id", "lessons"."position", "lessons"."topic_id" FROM "lessons" WHERE "lessons"."deleted_at" IS NULL AND "lessons"."topic_id" = $1  [["topic_id", 7297]]                                      
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

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add nested_select

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install nested_select

## Usage
Assume you have a relation users <- profile, and you want to preview users in a paginated feed, 
and you need only :photo attribute of a profile, with nested_select you can do it like this:  

```ruby
# this will preload profile with exact attributes: :id, :user_id and :photo
User.includes(:profile).select(profile: :photo).limit(10)
```

## Safety
How safe is the partial model loading? Earlier version of rails and activerecord would return nil in the case, 
when attribute wasn't selected from a DB, but rails 6 started to raise a ActiveModel::MissingAttributeError. 
So the major problem is already solved -- your code will not operate based on falsy blank values, it will raise an exception. 

## Known issues (0.2.0)
There is an issue in 0.2.0 though.

As for the version 0.2.0 you need to ensure all foreign keys are explicitly added to attributes selection tree, 
since rails will not raise an exception while zipping models to each other, it just will not match them


## Testing

```bash
docker compose run test 
```

## TODO
- [ ] Cover all relation combinations and add missing functionality
  - [ ] Ensure relations foreign keys are present on the selection
  - [ ] Ensure belongs_to will add a foreign_key column
- [ ] Optimize through relations ( since they loading a whole set of attributes )
- [ ] Separated rails version testing

## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alekseyl/nested_select. This project is intended to be a safe, 
welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NestedSelect project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).
