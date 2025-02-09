# Concept?
Covering each type of relation for a fixed set of features

Features to cover for each kind of relations:
- allows partial selection including
  - explicit selections
  - implicit selections of the reflections ( foreign and primary keys by default )
- does not breaks inverse_of
- works fine for at least of two levels of deep 

General features can be covered once:
- [x] does not affect any nested selection scopes, unless explicitly select something
- [x] merges selection scopes
- [x] does not interfere with root relation selection
- [x] nested custom attribute 

Models relations and combinations to test 

```

```

# Has some
User has_many user_profiles, UserProfile has_many avatars

Rem. I'm always freaking googling everytime I need to run single test so I'll just keep it here:

```ruby
bundle exec ruby -Itest test/test_through_reflections.rb x
```
