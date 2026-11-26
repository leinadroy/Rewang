<?php
declare(strict_types=1);

final class Router
{
    private array $routes = [];

    public function get(string $pattern, callable $handler): void    { $this->add('GET', $pattern, $handler); }
    public function post(string $pattern, callable $handler): void   { $this->add('POST', $pattern, $handler); }
    public function put(string $pattern, callable $handler): void    { $this->add('PUT', $pattern, $handler); }
    public function delete(string $pattern, callable $handler): void { $this->add('DELETE', $pattern, $handler); }

    /** Pola seperti "/users/{id}" menjadi parameter $params['id']. */
    public function add(string $method, string $pattern, callable $handler): void
    {
        $regex = preg_replace('#\{(\w+)\}#', '(?P<$1>[^/]+)', rtrim($pattern, '/') ?: '/');
        $this->routes[] = [$method, '#^' . $regex . '$#', $handler];
    }

    public function dispatch(string $method, string $path): never
    {
        $pathMatched = false;

        foreach ($this->routes as [$routeMethod, $regex, $handler]) {
            if (!preg_match($regex, $path, $m)) {
                continue;
            }
            $pathMatched = true;
            if ($routeMethod !== $method) {
                continue;
            }
            $params = array_filter($m, 'is_string', ARRAY_FILTER_USE_KEY);
            $handler($params);
            Response::json(null, 204);
        }

        $pathMatched
            ? Response::error('Method tidak diizinkan', 405)
            : Response::error('Endpoint tidak ditemukan', 404);
    }
}
