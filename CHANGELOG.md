## 1.0.0

- Initial version.

## 1.1.0

- Change the serialiser to use a map of components instead of a list.

## 1.1.1

- Add the entity serialiser json.

## 1.1.2

- Add component deserialisation method to entity serialiser.

## 1.1.3

- Add system get method to world.

## 1.2.0

- expose the component serialiser to the world.
- remove the need to pass the entity manager to the component serialiser.

## 1.2.1

- Fix entity deletion queue processing to prevent entities from being processed after deletion.
- Entity deletion queue is now processed after each system runs, ensuring proper entity lifecycle management.
- Add comprehensive entity deletion tests covering edge cases like cascading deletions and multi-system interactions.
