# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DarkTrader do
  let(:trader) { described_class.new }

  describe '#fetch_all_cryptos' do
    let(:cryptos) { trader.fetch_all_cryptos }

    it 'retourne un array non vide' do
      expect(cryptos).to be_an(Array)
      expect(cryptos).not_to be_empty
    end

    it 'retourne des hashs avec le bon format (symbole => prix)' do
      cryptos.first(10).each do |crypto|
        expect(crypto).to be_a(Hash)
        expect(crypto.keys.length).to eq(1)

        symbol = crypto.keys.first
        price = crypto.values.first

        expect(symbol).to be_a(String)
        expect(symbol).not_to be_empty

        expect(price).to be_a(Numeric)
        expect(price).to be >= 0
      end
    end

    it 'contient des cryptomonnaies connues comme BTC et ETH' do
      symbols = cryptos.map { |c| c.keys.first }

      expect(symbols).to include('BTC')
      expect(symbols).to include('ETH')
    end

    it 'retourne un nombre cohérent de cryptomonnaies (au moins 100)' do
      expect(cryptos.length).to be >= 100
    end

    it 'contient des prix réalistes pour BTC (> $1000)' do
      btc = cryptos.find { |c| c.keys.first == 'BTC' }
      expect(btc).not_to be_nil
      expect(btc['BTC']).to be > 1000
    end
  end
end
