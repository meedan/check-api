require_relative '../test_helper'

class CheckCldrTest < ActiveSupport::TestCase
  test "should load locales" do
    assert CLDR_LANGUAGES.keys.size > 0
  end

  test "should return localized language name" do
    assert_equal 'francês', CheckCldr.language_code_to_name('fr', 'pt')
    assert_equal 'xx', CheckCldr.language_code_to_name('xx', 'pt')
    assert_equal 'भोजपुरी', CheckCldr.language_code_to_name('bho', 'bho')
    I18n.expects(:locale).returns(:es)
    assert_equal 'francés', CheckCldr.language_code_to_name('fr')
    I18n.unstub(:locale)
  end

  test "should return localized languages" do
    languages = CheckCldr.localized_languages('pt')
    assert_equal 'Inglês', languages['en']
    assert_equal 'Árabe', languages['ar']
    assert_equal 'Francês', languages['fr']
  end
end
