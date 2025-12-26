# Capsule

A simple dependency injection framework for Haxe with compile-time verification.

## Installation

Install using [Lix](https://github.com/lix-pm):

`lix install gh:wartman/capsule`

Install using haxelib:

> Not available yet

## Using Capsule

> The following documentation is a work-in-progress and is incomplete.

As an example of how Capsule works we're going to put together a few robots. Once the principals are established we'll show how they apply to more realistic examples. Complete code can be found in the [example](example) folder.

### Creating Some Parts

Our first step is to create our robot's parts. First we'll create a `Robot` class that will hold everything together:

```haxe
package robot;

class Robot {
  public final head:Head;
  public final body:Body;
  public final legs:Legs;
  public final arms:Arms;

  public function new(head, body, legs, arms) {
    this.head = head;
    this.body = body;
    this.legs = legs;
    this.arms = arms;
  }
}
```

Just by creating a class with a constructor, we've given Capsule all the information it will need to satisfy `Robot`'s dependencies. In this case, it will need a `Head`, `Body`, `Legs` and `Arms`. We'll make all of these interfaces for flexibility later on. For example, here's how we'll define `Head`:

```haxe
package robot;

interface Head {
  public function lookAt(target:String):String;
}
```

We'll also create some standard implementations for each of these robot parts. For the most part these will be straightforward, such as an implementation for our robot's `Arms`:

```haxe
package robot.standard;

class StandardArms implements Arms {
  public function new() {}

  public function pickUp(target:String):String {
    return 'Picks up $target.';
  }
}
```

We'll do something a little different with the robot's `Head` and make that part also take a `Brain`:

```haxe
package robot.standard;

class StandardHead implements Head {
  final brain:Brain;

  public function new(brain) {
    this.brain = brain;
  }

  public function lookAt(target:String):String {
    return 'Looks at $target. ' + brain.consider(target);
  }
}
```

### Putting Things Together

Up to this point we haven't even touched Capsule, which is by design. Your code should not be coupled with a dependency injection framework, and Capsule makes sure it gets out of the way until it's needed.

Lets start using Capsule by creating a `StandardRobotModule`. We won't bind any robot parts yet, just the Robot itself.

```haxe
package robot.standard;

import capsule.*;

class StandardRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Robot).to(Robot);
  }
}
```

Next lets create a `main` function and get a robot so we can have it look around. We'll need to *compile* a container using the module we created, then *open* that container to get our robot out.

```haxe
import capsule.Container;
import robot.*;
import robot.standard.*;

function main() {
  Container.compile(
    new StandardRobotModule()
  ).open((robot:Robot, friend:FriendlyRobot) -> {
    trace(robot.head.lookAt('tree'));
  });
}
```

Importantly, this example *will not compile* as it currently stands. We want this! Capsule is telling us that the binding `Robot` has unmet dependencies, and rather than dealing with that at runtime we have to fix it now. Lets go back to our `StandardRobotModule` and bind the rest of our robot parts:

```haxe
package robot.standard;

import capsule.*;

class StandardRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Robot).to(Robot);
    container.bind(Brain).to(StandardBrain);
    container.bind(Head).to(StandardHead);
    container.bind(Body).to(StandardBody);
    container.bind(Arms).to(StandardArms);
    container.bind(Legs).to(StandardLegs);
  }
}
```

Our container will now compile and our robot will look at a tree.

### Making our robot friendly

Lets say we want a robot with a more friendly brain:

```haxe
package robot.friendly;

class FriendlyBrain implements Brain {
  public function new() {}

  public function consider(target:String):String {
    return 'Would like $target to be its friend.';
  }
}
```

This robot can use all the other standard parts, but we'll have to find a way to get this brain into the robot's head.

One solution might be to just swap out the brain in our `StandardRobotModule`:

```haxe
package robot.standard;

import capsule.*;
import robot.friendly.*;

class StandardRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Robot).to(Robot);
    container.bind(Brain).to(FriendlyBrain); // <- Changed here
    container.bind(Head).to(StandardHead);
    container.bind(Body).to(StandardBody);
    container.bind(Arms).to(StandardArms);
    container.bind(Legs).to(StandardLegs);
  }
}
```

This will work, but we'd like our default robot to keep the `StandardBrain`. Instead, let's create a `FriendlyRobot` typedef to differentiate it from the standard one:

```haxe
package robot.friendly;

typedef FriendlyRobot = Robot;
```

Let's also create a `FriendlyRobotModule` to bind our new friend:

```haxe
package robot.friendly;

import capsule.*;

class FriendlyRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(FriendlyRobot).to(Robot);
  }
}
```

This hasn't solved our problem yet. Dependencies are shared between modules, so this will still use our `StandardBrain`. One way to fix this might be bind to a function instead of a class. Capsule will scan the function's arguments and inject them, which means we can swap out the ones we don't want:

```haxe
package robot.friendly;

import capsule.*;

class FriendlyRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(FriendlyRobot).to((body:Body, legs:Legs, arms:Arms) -> new Robot(
      new Head(new FriendlyBrain()),
      body,
      legs,
      arms
    ));
  }
}
```

This will work, but it's clunky and brittle. If the order of arguments in Robot's constructor ever change or if we ever need to add another part of the Robot this code will break. Capsule has a better way to do this, and we can just tell the container to use a `FriendlyBrain` when building a `FriendlyRobot`:

```haxe
package robot.friendly;

import capsule.*;

class FriendlyRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(FriendlyRobot).to(Robot);
    container.when(FriendlyRobot).needs(Brain).give(FriendlyBrain); // <- Rebound `Brain`
  }
}
```

We also want there to only be one `FriendlyRobot` so we'll mark it as shared. This means that capsule will build it once and return a cached instance thereafter:

```haxe
package robot.friendly;

import capsule.*;

class FriendlyRobotModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(FriendlyRobot).to(Robot).share(); // <- Added `share()`
    container.when(FriendlyRobot).needs(Brain).give(FriendlyBrain);
  }
}
```

Back in our main function, let's also get a `FriendlyRobot` to look at a tree. We'll do it wrong first to illustrate Capsule's dependency verification again:

```haxe
import capsule.Container;
import robot.*;
import robot.standard.*;
import robot.friendly.*;

function main() {
  Container.compile(
    new StandardRobotModule()
  ).open((robot:Robot, friend:FriendlyRobot) -> {
    trace(robot.head.lookAt('tree'));
    trace(friend.head.lookAt('tree'));
  });
}
```

This *will not work* as the compiled container does not have a `FriendlyRobot` in it yet. To fix this, we simply need to add our `FriendlyRobotModule`:

```haxe
import capsule.Container;
import robot.*;
import robot.standard.*;
import robot.friendly.*;

function main() {
  Container.compile(
    new StandardRobotModule(),
    new FriendlyRobotModule()
  ).open((robot:Robot, friend:FriendlyRobot) -> {
    trace(robot.head.lookAt('tree'));
    trace(friend.head.lookAt('tree'));
  });
}
```

## Advanced Concepts and Real-world examples

<!-- Todo: `share()`, `when(...).resolved(...)`, etc. -->

> Coming soon