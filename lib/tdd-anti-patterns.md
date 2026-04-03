# Testing Anti-Patterns

Reference doc loaded by `/z:implement` when writing tests.
Avoid these patterns to ensure tests actually catch bugs.

## Testing Mocks Instead of Real Code

**Bad:**
```typescript
test('sends email', () => {
  const mock = jest.fn();
  sendEmail(mock);
  expect(mock).toHaveBeenCalled();
});
```
This tests that you called the mock, not that email sending works.

**Good:**
```typescript
test('sends email with correct subject', async () => {
  const result = await sendEmail({
    to: 'test@example.com',
    subject: 'Welcome',
    body: 'Hello',
  });
  expect(result.status).toBe('sent');
  expect(result.subject).toBe('Welcome');
});
```

## Meaningless Assertions

**Bad:**
```typescript
expect(result).toBeDefined();
expect(user).toBeTruthy();
expect(list.length).toBeGreaterThan(0);
```
These pass for almost any value. They don't test behavior.

**Good:**
```typescript
expect(result).toEqual({ id: 1, name: 'Alice' });
expect(user.role).toBe('admin');
expect(list).toHaveLength(3);
```

## Testing Implementation Instead of Behavior

**Bad:**
```typescript
test('uses HashMap internally', () => {
  const cache = new Cache();
  expect(cache._store instanceof Map).toBe(true);
});
```

**Good:**
```typescript
test('returns cached value on second call', () => {
  const cache = new Cache();
  cache.set('key', 'value');
  expect(cache.get('key')).toBe('value');
});
```

## Giant Test Setup

If test setup is 50 lines and the assertion is 1 line, the design is wrong.
Extract helpers, or simplify the code under test.

## Testing Private Methods

If you need to test a private method, it should probably be public
on a smaller, extracted class/module.

## Flaky Tests

Tests that pass sometimes and fail sometimes are worse than no tests.
They train you to ignore failures. Fix or delete them.

Common causes:
- Timing dependencies (use condition-based waiting, not sleeps)
- Shared mutable state between tests (isolate)
- External service dependencies (mock at the boundary)
- Random data without fixed seeds

## Over-Mocking

If you mock more than 2 dependencies, the test is testing wiring, not behavior.
Consider integration tests or simplifying the code's dependency graph.

## Test Names That Don't Describe Behavior

**Bad:** `test('test1')`, `test('it works')`, `test('handles edge case')`

**Good:** `test('rejects empty email with validation error')`,
`test('retries failed request 3 times before throwing')`

The test name should tell you what broke when it fails.
