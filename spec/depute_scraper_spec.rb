# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeputeScraper do
  let(:scraper) { described_class.new }

  describe '#get_deputes_urls' do
    let(:urls) { scraper.get_deputes_urls }

    it 'retourne un array non vide' do
      expect(urls).to be_an(Array)
      expect(urls).not_to be_empty
    end

    it 'retourne des hashs avec les clés attendues' do
      urls.first(5).each do |depute|
        expect(depute).to be_a(Hash)
        expect(depute).to have_key(:full_name)
        expect(depute).to have_key(:first_name)
        expect(depute).to have_key(:last_name)
        expect(depute).to have_key(:url)
      end
    end

    it 'contient un nombre cohérent de députés (environ 577)' do
      expect(urls.length).to be_between(500, 600)
    end

    it 'contient des URLs valides pointant vers assemblee-nationale.fr' do
      urls.first(10).each do |depute|
        expect(depute[:url]).to include('assemblee-nationale.fr')
        expect(depute[:url]).to include('/deputes/fiche/')
      end
    end
  end

  describe '#get_depute_info' do
    it 'récupère l\'email d\'un député (Gabriel Attal)' do
      url = 'https://www2.assemblee-nationale.fr/deputes/fiche/OMC_PA722190'
      info = scraper.get_depute_info(url)

      expect(info).not_to be_nil
      expect(info).to have_key(:email)
      expect(info[:email]).to match(/@assemblee-nationale\.fr$/)
    end
  end

  describe '#fetch_all_deputes', :slow do
    it 'récupère les informations de plusieurs députés' do
      urls = scraper.get_deputes_urls.first(3)

      deputes = []
      urls.each do |depute|
        info = scraper.get_depute_info(depute[:url])
        if info && info[:email]
          deputes << {
            'first_name' => depute[:first_name],
            'last_name' => depute[:last_name],
            'email' => info[:email]
          }
        end
        sleep(0.3)
      end

      expect(deputes).to be_an(Array)
      expect(deputes.length).to be > 0

      deputes.each do |depute|
        expect(depute).to be_a(Hash)
        expect(depute).to have_key('first_name')
        expect(depute).to have_key('last_name')
        expect(depute).to have_key('email')
        expect(depute['email']).to match(/@assemblee-nationale\.fr$/)
      end
    end
  end
end
