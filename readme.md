> Note:
>
> This branch is working on Capsule 2, a simplified version of Capsule that will
> (hopefully) add some compile-time checks for dependencies. Right now
> the new code can be found in `src/capsule2`.

Capsule 2
=========

[![Build Status](https://travis-ci.com/wartman/capsule.svg?branch=master)](https://travis-ci.com/wartman/capsule)


Capsule is a minimal, easy to use dependency-injection/IoC library.

Getting Started
---------------

Version 2 is not ready for use yet! It will have a lot of improvements over version 1, including:

- Much simpler macro code (not really a feature, but a major issue with the old version).
- A more opinionated, minimal API.
  - This includes removing all metadata (like `@:inject.tag`) AND the concept of tags entirely. Typedefs do the same thing and are more portable and discoverable than strings:
```haxe
// old:
container.map(String, 'foo').to('foo');

// new:
typedef Foo = String;

container.map(Foo).to('foo');
```
  - Classes __only__ use constructor injection now, no more injecting properties. I never had to use property injection in practice anyway, and this approach helps ensure that classes are less coupled to Capsule to work.
- Any function can act as a provider, not just anonymous ones passed to a mapping function.

```haxe
// You used to ONLY be able to do this:
container.map(String).to(function (service:StringService) {
  return service.getString();
});

// ...but now you can do this:
function stringProvider(service:StringService) {
  return service.getString();
}
container.map(String).to(stringProvider);

// ...which should open some possiblities up down the road.
//
// For example, maybe we have a database with some complex config options.
// Now we can do this:
container.map(DatabaseService).to(Database.createFromConfig).share();
```
- Compile-time dependency tracking (hopefully). Ideally, you shouldn't be able to compile an app if some services aren't provided. Still figuring out how to do this one.
