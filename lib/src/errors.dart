part of dart_di;

/// Base class for all container related errors.
class ContainerError {}

/// Error related to dependency resolution. Normally thrown when trying to
/// get an entry from container.
class DependencyError extends ContainerError {}
