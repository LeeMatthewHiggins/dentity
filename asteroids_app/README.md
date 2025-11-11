# Asteroids - Dentity ECS Example

A classic Asteroids game implementation demonstrating the Dentity Entity-Component-System (ECS) framework.

## About

This app showcases how to build a complete game using the Dentity ECS architecture. It includes:

- **Components**: Ship, Asteroid, Laser, InputState, Position, Velocity, Rotation, Bounds, Lifetime
- **Systems**: Input handling, movement, rotation, collision detection, weapon firing, bounds wrapping
- **Game mechanics**: Classic asteroids gameplay with screen wrapping and asteroid splitting

## Controls

- **Arrow Left/Right**: Rotate ship
- **Arrow Up**: Fire thruster
- **Space**: Fire laser
- **Enter**: Restart game (when game over)

## Running the Game

### macOS
```bash
flutter run -d macos
```

### Web
```bash
flutter run -d chrome
```

## Architecture Highlights

### Components
The game uses both custom components and shared components from the Dentity examples library:

- `Ship` - Tag component marking the player entity
- `Asteroid` - Stores size and point value
- `Laser` - Tag component for projectiles
- `InputState` - Tracks keyboard input state
- `ThrustForce` - Ship acceleration magnitude
- `Bounds` - World dimensions for wrapping

### Systems
Systems process entities with specific component combinations:

- `InputSystem` - Converts keyboard input to ship rotation
- `ThrustSystem` - Applies thrust force based on ship orientation
- `MovementSystem` - Updates positions based on velocity
- `AsteroidsRotationSystem` - Rotates entities
- `BoundsWrappingSystem` - Wraps entities around screen edges
- `LaserSpawnSystem` - Creates laser projectiles
- `AsteroidsCollisionSystem` - Handles collisions and asteroid splitting
- `AsteroidsLifetimeSystem` - Removes entities after their lifetime expires

### Game Flow
1. World initialization creates the ship and initial asteroids
2. Flutter ticker drives the ECS update loop
3. Custom painter renders all entities based on their components
4. Keyboard input is captured and stored in InputState component
5. Systems process entities each frame to update game state

## Code Structure

```
lib/
├── main.dart              # Flutter app and game UI
└── [Dentity examples]     # ECS components and systems

../lib/src/examples/
├── asteroids_components.dart  # Game-specific components
├── asteroids_systems.dart     # Game systems
└── asteroids_example.dart     # World factory and entity spawners
```

## Learning Points

This example demonstrates:

- How to structure a game using ECS
- Separating game logic into focused systems
- Using tag components for entity identification
- Handling user input in an ECS architecture
- Custom rendering with Flutter CustomPainter
- Entity lifecycle management (creation and destruction)
- Component-based collision detection

## License

Part of the Dentity ECS framework examples.
