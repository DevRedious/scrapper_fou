# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MairieScraper do
  let(:scraper) { described_class.new }

  describe '#get_townhall_urls' do
    let(:urls) { scraper.get_townhall_urls }

    it 'retourne un array non vide' do
      expect(urls).to be_an(Array)
      expect(urls).not_to be_empty
    end

    it 'retourne des hashs avec les clés :name et :url' do
      urls.first(5).each do |townhall|
        expect(townhall).to be_a(Hash)
        expect(townhall).to have_key(:name)
        expect(townhall).to have_key(:url)
        expect(townhall[:name]).to be_a(String)
        expect(townhall[:url]).to be_a(String)
      end
    end

    it 'contient un nombre cohérent de mairies (environ 182 pour le Val d\'Oise)' do
      expect(urls.length).to be_between(170, 190)
    end

    it 'contient des URLs valides pointant vers service-public.gouv.fr' do
      urls.first(10).each do |townhall|
        expect(townhall[:url]).to include('lannuaire.service-public.gouv.fr')
        expect(townhall[:url]).to include('/ile-de-france/val-d-oise/')
      end
    end
  end

  describe '#get_townhall_email' do
    it 'récupère l\'email d\'une mairie à partir de son URL (Ableiges)' do
      url = 'https://lannuaire.service-public.gouv.fr/ile-de-france/val-d-oise/55e63c96-f8a4-424c-a9fd-52ddf515b6ef'
      email = scraper.get_townhall_email(url)

      expect(email).not_to be_nil
      expect(email).to be_a(String)
      expect(email).to match(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
    end

    it 'retourne un email avec un format valide' do
      url = 'https://lannuaire.service-public.gouv.fr/ile-de-france/val-d-oise/b01da037-e547-48a7-a1f2-a346d5e63f14'
      email = scraper.get_townhall_email(url)

      if email
        expect(email).to match(/@/)
        expect(email).to match(/\.[a-zA-Z]{2,}$/)
      end
    end
  end

  describe '#fetch_all_emails', :slow do
    it 'récupère les emails de plusieurs mairies du Val d\'Oise' do
      urls = scraper.get_townhall_urls.first(5)

      emails = []
      urls.each do |townhall|
        email = scraper.get_townhall_email(townhall[:url])
        emails << { townhall[:name] => email } if email
        sleep(0.2)
      end

      expect(emails).to be_an(Array)
      expect(emails.length).to be > 0

      emails.each do |entry|
        expect(entry).to be_a(Hash)
        expect(entry.keys.length).to eq(1)

        name = entry.keys.first
        email = entry.values.first

        expect(name).to be_a(String)
        expect(email).to match(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
      end
    end
  end
end
