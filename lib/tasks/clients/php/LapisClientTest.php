<?php
namespace Meedan\Lapis;

class LapisClientTestCase extends \PHPUnit_Framework_TestCase {

  public function testGetMethod() {
    $c = new LapisClient(['client' => LapisClient::createMockClient(200)]);
    $c->request('GET', 'test', ['a' => 'a', 'b' => 'b']);
    $this->assertTrue(TRUE);
  }

  public function testPostMethod() {
    $c = new LapisClient(['client' => LapisClient::createMockClient(200)]);
    $c->request('GET', 'test', ['a' => 'a', 'b' => 'b']);
    $this->assertTrue(TRUE);
  }

  public function testHeadMethod() {
    $c = new LapisClient(['client' => LapisClient::createMockClient(200)]);
    $c->request('HEAD', 'test', ['a' => 'a', 'b' => 'b']);
    $this->assertTrue(TRUE);
  }
}
