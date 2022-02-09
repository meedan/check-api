require 'active_support/concern'

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      {
        # Button labels
        main_state_button_label: {
          en: 'Cancel',
          pt: 'Cancelar'
        },
        search_state_button_label: {
          en: 'Submit',
          pt: 'Enviar'
        },
        add_more_details_state_button_label: {
          en: 'Add more information',
          pt: 'Adicionar mais'
        },
        search_result_is_relevant_button_label: {
          en: 'Yes',
          pt: 'Sim'
        },
        search_result_is_not_relevant_button_label: {
          en: 'No',
          pt: 'Não'
        },
        privacy_statement: {
          en: 'Privacy statement',
          pt: 'Política de privacidade'
        },
        subscription_confirmation_button_label: {
          en: 'Change',
          pt: 'Alterar'
        },
        confirm_preferred_language: {
          en: 'Please confirm your preferred language:',
          pt: 'Confirme seu idioma'
        },
        languages: {
          en: 'Languages',
          pt: 'Idiomas'
        },
        main_menu: {
          en: 'Main menu',
          pt: 'Menu principal'
        },
        languages_and_privacy_title: {
          en: 'Languages and Privacy',
          pt: 'Idiomas e privacidade'
        },
        subscribed: {
          en: 'Subscribed',
          pt: 'Inscrito'
        },
        unsubscribed: {
          en: 'Unsubscribed',
          pt: 'Não-inscrito'
        }
      }[key.to_sym][language.gsub(/[-_].*$/, '').to_sym]
    end
  end
end
