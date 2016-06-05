<?php
namespace Meedan\Lapis;

class LapisException extends \Exception {}
class LapisClientMethodNotHandledException extends LapisException {}

class LapisClient {
  // LapisClient::config passed by the client application.
  var $config = [
    'host' => 'UNSET!',
    'token_name' => 'UNSET!',
    'token_value' => 'UNSET!',
    'client' => null,
  ];

  // Lapis client constructor
  // @param $config
  function __construct($config = []) {
    $this->config = array_merge($this->config, $config);

    // Create the Guzzle client if none was passed.
    // First set up logging.
    if (empty($this->config['client'])) {
      $logger = new \Monolog\Logger('Logger');
      $logger->pushHandler(new \Monolog\Handler\ErrorLogHandler());
      $logger->addInfo("Starting default client.");
      $handler = \GuzzleHttp\HandlerStack::create();
      $handler->push(new \Concat\Http\Middleware\Logger($logger));
      $this->config['client'] = new \GuzzleHttp\Client([
        'base_uri' => $this->config['host'],
        'handler' => $handler,
      ]);
    }
  }

  // Lapis request function.
  // @param $method string
  //   HTTP verb, 'GET', 'POST', etc.
  // @param $path string
  //   Endpoint path (minus the host)
  // @param $params
  //   Map of arguments to send endpoint
  //   In case of 'GET' or 'HEAD', it gets converted to a URL query
  //   In case of 'POST', gets onverted to FORM parameters for application/x-www-form-urlencoded
  //   TODO: Handle other verbs
  // @param $headers
  //   Map of HTTP headers
  //   The chosen Lapis API token header is set within this function
  // @return
  //   JSON-decoded response from service
  public function request($method, $path, $params = [], $headers = []) {
    $headers[$this->config['token_name']] = $this->config['token_value'];
    switch (strtoupper($method)) {
      case 'GET':
      case 'HEAD': $params_key = 'query'; break;
      case 'POST': $params_key = 'form_params'; break;
      default: {
        throw new LapisClientMethodNotHandledException();
      }
    }
    $res = $this->config['client']->request($method, $path, [
      'headers' => $headers,
      'http_errors' => false,
      $params_key => $params,
    ]);
    return json_decode($res->getBody()->getContents());
  }

  // Create a mock client that returns a predefined response.
  // @param $status
  //   Response HTTP status code
  // @param $body
  //   Response body object (will be JSON-encoded in this function)
  // @param $headers
  //   Array of response HTTP headers
  // @return
  //   \GuzzleHttp\Client with proper mock configuration
  public static function createMockClient($status = 200, $body = '', $headers = []) {
    $mock = new \GuzzleHttp\Handler\MockHandler([
        new \GuzzleHttp\Psr7\Response($status, $headers, json_encode($body)),
    ]);
    $handler = \GuzzleHttp\HandlerStack::create($mock);
    $logger = new \Monolog\Logger('Logger');
    $logger->pushHandler(new \Monolog\Handler\ErrorLogHandler());
    $logger->addInfo("Starting mock client.");
    $handler->push(new \Concat\Http\Middleware\Logger($logger));
    return new \GuzzleHttp\Client(['handler' => $handler]);
  }
}
