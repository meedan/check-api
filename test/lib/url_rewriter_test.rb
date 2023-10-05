require_relative '../test_helper'

class UrlRewriterTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test 'should shorten URL' do
    url = nil
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      url = UrlRewriter.shorten('https://meedan.com/check', nil)
    end
    assert_match /^https:\/\/chck.media\/[^\/]{8}/, url
  end

  test 'should add UTM code to URL' do
    assert_equal 'https://meedan.com/?lang=en&utm_source=test', UrlRewriter.utmize('https://meedan.com/?lang=en', 'test')
  end

  test 'should return original URL if it is not valid' do
    assert_equal 'Foo Bar', UrlRewriter.utmize('Foo Bar', 'test')
  end

  test 'should shorten and UTMize URLs in a text' do
    Shortener::ShortenedUrl.any_instance.stubs(:unique_key).returns('1234xyzw')
    input = 'Hey, visit https://meedan.com and https://checkmedia.org/check?lang=en :)'
    output = 'Hey, visit https://chck.media/1234xyzw and https://chck.media/1234xyzw :)'
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      assert_equal output, UrlRewriter.shorten_and_utmize_urls(input, 'test')
    end
  end

  test 'should add https:// to URLs' do
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      UrlRewriter.shorten_and_utmize_urls('Visit meedan.com/check/pt now', nil)
    end
    assert_equal 'https://meedan.com/check/pt', Shortener::ShortenedUrl.last.url
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      UrlRewriter.shorten_and_utmize_urls('Visit https://meedan.com/check/en now', nil)
    end
    assert_equal 'https://meedan.com/check/en', Shortener::ShortenedUrl.last.url
  end

  test 'should fallback to long URL if shortening fails' do
    Shortener::ShortenedUrl.stubs(:generate).returns(nil)
    url = random_url
    assert_nothing_raised do
      assert_equal url, UrlRewriter.shorten(url, nil)
    end
  end

  test 'should shorten Arabic URL' do
    shortened = nil
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      shortened = UrlRewriter.shorten_and_utmize_urls('Visit https://fatabyyano.net/هذا-المقطع-قديم،-ولا-يبين-لحظة-إنقاذ-شا/ for more information.', nil)
    end
    assert_equal 'https://fatabyyano.net/%D9%87%D8%B0%D8%A7-%D8%A7%D9%84%D9%85%D9%82%D8%B7%D8%B9-%D9%82%D8%AF%D9%8A%D9%85%D8%8C-%D9%88%D9%84%D8%A7-%D9%8A%D8%A8%D9%8A%D9%86-%D9%84%D8%AD%D8%B8%D8%A9-%D8%A5%D9%86%D9%82%D8%A7%D8%B0-%D8%B4%D8%A7/', Shortener::ShortenedUrl.last.url
    assert_match /^Visit https:\/\/chck\.media\/[a-zA-Z0-9]+ for more information\.$/, shortened
  end

  test 'should not shorten decoded Arabic URL' do
    url = 'https://fatabyyano.net/%da%af%d8%b1%d8%aa%db%95-%da%a4%db%8c%d8%af%db%8c%db%86%db%8c%db%8c%db%95%da%a9%db%95-%d8%b3%d8%a7%d8%ae%d8%aa%db%95%db%8c%db%95-%d9%88-%d9%84%d8%a7%d9%81%d8%a7%d9%88-%d9%88-%d8%b2%d8%b1%db%8c%d8%a7/'
    shortened = nil
    stub_configs({ 'short_url_host_display' => 'https://chck.media' }) do
      shortened = UrlRewriter.shorten_and_utmize_urls("فتبينوا  | Visit #{url} for more information.", nil)
    end
    assert_equal url, Shortener::ShortenedUrl.last.url
    assert_match /^فتبينوا  \| Visit https:\/\/chck\.media\/[a-zA-Z0-9]+ for more information\.$/, shortened
  end
end
