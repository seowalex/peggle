# CS3217 Problem Set 4

**Name:** Seow Alex

**Matric No:** A0199262U

## Dev Guide
The code for this project can be broadly separated into 6 categories, which will be elaborated upon below:

* Persistence
* Models
* Views/View Models
* Physics Engine
* Game Engine
* Utilities

### Persistence
All database related properties and methods, such as setting up the database schema, inserting records and fetching records, can be found in `AppDatabase.swift`. The file also contains methods for creating the preloaded levels when the app is first run.

The actual setup of databases for production and testing purposes can be found in `AppDatabase+Persistence.swift`. The application also makes use of Combine, a framework to handle asynchronous events such as the updating of the database, so that views can be synchronised with the database at all times.

### Models
The application consists of record models (`LevelRecord`, `PegRecord` and `BlockRecord`) and game models (`Level`, `Element`, `Peg` and `Block`). The record models define the structure used for storing the respective records in the database, along with some helper functions to support database queries.

The game models are used to represent the game objects in the level editor, particularly `Peg` and `Block`, which represent pegs and blocks respectively. They inherit from an `Element` to share some common properties.

### Views and View Models
The application uses an MVVM architecture, where each view is associated with a view model, which handles all the database saving and fetching.

There are a number of views, such as `MainMenuView`, `LevelEditorView` and `LevelPlayerView`, all of which are associated with their respective view models, and handle the display of different screens, such as the main menu or level editor. More details about `LevelPlayerView`, which is used to show the level player, can be found in the below sections.

### Physics Engine
Underlying the whole game is a physics engine, which is encapsulated with a `PhysicsWorld` and many `PhysicsBodies`.

The `PhysicsBody` represents a body in the physics simulation, and keeps track of the bodies' properties, such as mass, area, position, rotation and velocity, amongst other things. The `PhysicsBody` also handles collision checking between itself and other `PhysicsBodies` by making use of the Separating Axis Theorem (SAT), and keeps track of the forces applied to the it, so that it can update its position and velocity using the `update` method.

The `PhysicsWorld` class keeps track of global variables such as gravity and simulation speed, and handles the application of gravity, updating the individual bodies by calling their `update` methods, and resolving any collisions between bodies through its `update` method.

### Game Engine
For my game engine, I made use of the Entity-Component-System (ECS) architecture. ECS models game objects based on what each game object *does*, as opposed to what each game object *is*. Hence, instead of each game object inheriting from a base class, they are instead composed of several components that combine to provide the desired behaviour.

To actually display the game, I make use of a `LevelPlayerView` and a `LevelPlayerViewModel`. The `LevelPlayerView` is a relatively simple `View`, whose only purpose is to display a list of components passed to it by the `LevelPlayerViewModel`, which represents a list of game objects to be rendered. 

The `LevelPlayerViewModel` gets this list of components by subscribing to a `GameRenderer`, which publishes a list of components to be rendered. The `GameEngine` is also responsible for instantiating the `GameRenderer` and a `GameEngine` to render and run the game respectively. Lastly, the `LevelPlayerViewModel` also forwards any drag events from the `LevelPlayerView` to the `GameEngine`, so that it can be appropriately handled.

To render the game, a `GameRenderer` is used. Its responsibility is to call the `GameEngine`'s `update` method, at a rate that synchronises to the refresh rate of the display by making use of a `CADisplayLink`, and publishing a list of game objects to be rendered.

The `GameEngine` contains the bulk of the game logic, which utilises the ECS architecture. The game engine is made of `Systems`, `Entities` and `Components`.

`Entities` are simply a wrapper around a `UUID` that represents each game object. These `Entities` are kept track of by an `EntityManager`, which holds a dictionary mapping `Entities` to their `Components`, along with helper methods to add and retrieve `Entities` and `Components`.

As explained earlier, each `Component` stores an aspect of what a game object does. For example, the `RenderComponent` stores information such as position, rotation, size and image name, to render a game object. On the other hand, the `PhysicsComponent` stores a `PhysicsBody`, to provide the physics simulation for a game object.

These `Components` are simply raw data related to that aspect of the game object, and the actual functionality is provided in the `Systems`. These `Systems` run continuously, and performs global actions on every `Entity` that possesses the corresponding `Component`. For example, the `RenderSystem` retrieves the corresponding `PhysicsComponent` for every `Entity` that possesses a `RenderComponent`, and updates the `RenderComponent`'s position, rotation and size so that the object can be rendered.

In this way, `Entities` are just a container for `Components`, which are just raw data pertaining to a certain aspect of a game object, and any logic is stored either in the `GameEngine` itself, or a related `System`. The `GameEngine` also handles miscellaneous tasks such as handling drag events, instantiating `Entities`, and removing pegs when the ball exits the stage or is stuck.

## Rules of the Game
Please write the rules of your game here. This section should include the
following sub-sections. You can keep the heading format here, and you can add
more headings to explain the rules of your game in a structured manner.
Alternatively, you can rewrite this section in your own style. You may also
write this section in a new file entirely, if you wish.

### Cannon Direction
Aim the cannon by tapping and dragging anywhere within the playable area. The cannon should aim towards the tapped location. Release the tap to fire the cannon.

### Bucket Effect
When the ball enters the bucket, you earn a free ball and the number of balls get incremented.

### Win and Lose Conditions
1. To win, clear all the orange pegs
2. You start with 10 balls. Every time you shoot a ball, the number of balls decrease. You lose if you run out of balls and there are still orange pegs remaining in the game.
3. For the game to end, you need to either run out of balls or clear all the pegs, whichever comes first.

To ensure that the game always terminates to a win or lose state, the ball must be unstuck if stuck. If the ball is stuck due to a peg, the peg will be removed early. If the ball is stuck due to a block, the block will temporarily allow the ball to phase through.

### Powerup Selection
To select the powerup activated by the green pegs, use the picker at the top right corner in the level select or level editor screen.

## Level Designer Additional Features
To rotate, resize or toggle the oscillation of a peg/block, first select the peg/block by tapping on it. Take note that if rotating or resizing the peg/block results in it colliding with another peg/block or extending out of the playable area, the operation will not be allowed.

### Peg/Block Rotation
To rotate a peg/block, tap and drag the circular rotation handle at the top of the peg/block. 

### Peg/Block Resizing
To resize a peg/block, tap and drag one of the four square resize handles around the peg/block. Both the width and height will be changed for pegs, while only one of them will be changed for blocks.

### Peg/Block Oscillation
To toggle oscillation for a peg/block, tap and hold a peg/block (this means that you can no longer tap and hold to remove a peg/block). Green and red diamond handles should appear, denoting the path of the oscillation. To adjust the path, drag the green and red handles to the desired length. The colours can also be flipped by dragging to the opposite side. To adjust the frequency of the oscillation, drag the orange diamond handle in the middle of the peg/block to the appropriate height. If the orange handle is at the top of the element, it will oscillate at the maximum frequency of 1 Hz, while dragging the orange handle to the bottom handle will cause it to oscillate at 0 Hz (i.e. not oscillate at all).

## Bells and Whistles
### Aim Trajectory
While aiming the cannon, the trajectory of the shot can be visualised in real time, stopping at first collision (unless the Super Guide powerup is active).

### Additional Powerups
#### Super Guide
When this powerup is activated, the aim trajectory will extend to 2 collisions for the next 3 turns.

### Number of Pegs/Blocks in Level Editor
The number of pegs/blocks placed in the level editor is shown in the palette for easy reference.

### Enhanced selection in Level Editor
Pegs/blocks in the level editor can be selected and dragged in an intuitive manner, and will snap back to their original position if the player attempts to move/rotate/resize them such that they collide with another peg/block or extend out of the playing area.

### Prematurely remove pegs/disable blocks
To ensure that the ball does not become stuck, pegs will be prematurely removed, and blocks will temporarily allow balls to phase through.

### Level Select previews
Levels can be previewed in the level select screen, which will automatically be updated when the levels are edited.

### Scoring System
A scoring system that attempts to closely mimic Peggle's has been implemented, complete with multipliers and purple pegs. Free balls are also awarded when the player scores above 25000, 75000 and 125000 points, and when the player catches the ball with the bucket. 

### Game UI
The current score, as well as the balls and orange pegs remaining, can be seen below the playing area.

## Tests
### Add peg (not overlapping/out of bounds)

1. Select the blue peg button
2. Tap on an empty space on the board
3. A blue peg should be added
4. Repeat steps 1 to 3 with the orange peg button

### Add peg (overlapping/out of bounds)

1. Select the blue peg button
2. Tap on an empty space on the board
3. A blue peg should be added
4. Tap on the same spot that was previously tapped
5. A peg will not be added as it will overlap with an existing peg
6. Tap on the toolbar
7. A peg will not be added as it is out of bounds
8. Repeat steps 1 to 7 with the orange peg button

### Delete peg (long press)

1. Add a blue peg
2. Long press the blue peg
3. The blue peg should be deleted
4. Repeat steps 1 to 3 with the orange peg button

### Delete peg (tap)

1. Add a blue peg
2. Select the delete button
3. Tap the blue peg
4. The blue peg should be deleted
5. Repeat steps 1 to 4 with the orange peg button

### Drag peg (not overlapping/out of bounds)

1. Add a blue peg
2. Tap and drag the blue peg to a new position
3. The blue peg should be moved
4. Repeat steps 1 to 3 with the orange peg button

### Drag peg (overlapping/out of bounds)

1. Add two blue pegs
2. Tap and drag one blue peg to the other blue peg
3. The blue peg should not be moved as it will overlap with an existing peg
4. Tap and drag one blue peg offscreen or into the toolbar
5. The blue peg should not be moved as it is out of bounds
6. Repeat steps 1 to 5 with the orange peg button

### Saving a level

1. Add some pegs
2. Type a name for the level in the text box
3. Tap the save button
4. A popup should show, and the level should be saved

### Loading a level

1. Save a level
2. Tap the load button
3. A list of levels should be shown
4. Tap any level
5. The corresponding level should be loaded

### Resetting a level

1. Add some pegs
2. Tap the reset button
3. The level should be resetted

### Start Level
1. Use the level editor to place pegs as desired
2. Tap the start button
3. The designed level should be ready to be played

### Ball Launch
1. Start a level
2. Tap and drag anywhere in the playing field: the cannon should rotate to face the direction of the tap
3. Release the tap
4. The ball should be launched in the corresponding direction

### Ball Launch (direction restriction)
1. Start a level
2. Try to rotate the cannon such that it launches the ball upwards
3. The cannon should not be able to rotate or launch a ball more than 60 degrees away from the center

### Ball Launch (number of balls restriction)
1. Start a level
2. Launch a ball
3. Should be unable to launch another ball (or rotate the cannon) while the previous ball has not exited the stage

### Ball Movement
1. Start a level
2. Launch a ball
3. The ball should travel in a parabolic trajectory affected by both gravity and the launch force

### Ball Collision
1. Start a level
2. Launch a ball at a peg
3. The ball should collide with the peg and bounce away in a realistic manner
4. The ball should also collide with the wall and bounce away in a realistic manner

### Peg Lighting
1. Start a level
2. Launch a ball at a peg
3. The peg should be lit, and remain lit while the ball is still on the stage

### Peg Removal
1. Start a level
2. Launch a ball at a peg
3. Any hit pegs should be lit
4. When the ball exits the stage, any lit pegs should be removed

### Peg Removal (stuck)
1. Start a level
2. Launch a ball such that it is stuck between pegs and cannot exit the stage
3. Any hit pegs should be lit
4. After a short delay, the lit peg closest to the ball should be removed
5. The ball should continue hitting pegs or exiting the stage

## Written Answers

### Reflecting on your Design
> Now that you have integrated the previous parts, comment on your architecture
> in problem sets 2 and 3. Here are some guiding questions:
> - do you think you have designed your code in the previous problem sets well
>   enough?
> - is there any technical debt that you need to clean in this problem set?
> - if you were to redo the entire application, is there anything you would
>   have done differently?

Overall, I am fairly happy with my architecture from Problem Sets 2 and 3, and did not have to clean up a large amount of technical debt from previous problem sets. One thing I have found out is that while SwiftUI provides a lot of sensible defaults, and makes it easy to bootstrap an application, custom behaviour can sometimes be hard to implement, and requires falling back onto UIKit. An example is custom alert boxes, which is not possible in SwiftUI.

For my level editor from Problem Set 2, I was able to extend it to include blocks with not much changes. I considered using an Entity-Component-System architecture used in my game engine for my game editor, but after several tries, I deemed it as too much effort and probably not a good fit for my level editor. This is because my level editor requires a lot of custom views with custom drag gestures that are non-reusable, which did not fit well with ECS.

Given that my level player used ECS, I did not face problems with multiple levels of inheritance. However, I did find that managing global state is slightly tricky with ECS. I ended up creating components that are only used once to keep track of global state, which does not seem like a good practice. If I redid the entire application, I would probably try to rely less on ECS, and use global states whenever appropriate.
