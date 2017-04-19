class MachineTranslationWorker
  include Sidekiq::Worker

  def perform(target, author)
    target = YAML::load(target)
    author = YAML::load(author)
    bot = Bot::Alegre.default
    bot.get_mt_from_alegre(target, author) unless bot.nil?
  end

end
