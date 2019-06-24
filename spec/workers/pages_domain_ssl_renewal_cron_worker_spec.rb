# frozen_string_literal: true

require 'spec_helper'

describe PagesDomainSslRenewalCronWorker do
  include LetsEncryptHelpers

  subject(:worker) { described_class.new }

  before do
    stub_lets_encrypt_settings
  end

  describe '#perform' do
    let!(:domain) { create(:pages_domain) }
    let!(:domain_with_enabled_auto_ssl) { create(:pages_domain, auto_ssl_enabled: true) }
    let!(:domain_with_obtained_letsencrypt) { create(:pages_domain, :letsencrypt, auto_ssl_enabled: true) }
    let!(:domain_without_auto_certificate) do
      create(:pages_domain, :without_certificate, :without_key, auto_ssl_enabled: true)
    end

    let!(:domain_with_expired_auto_ssl) do
      create(:pages_domain, :letsencrypt, :with_expired_certificate)
    end

    it 'enqueues a PagesDomainSslRenewalWorker for domains needing renewal' do
      [domain_without_auto_certificate,
       domain_with_enabled_auto_ssl,
       domain_with_expired_auto_ssl].each do |domain|
        expect(PagesDomainSslRenewalWorker).to receive(:perform_async).with(domain.id)
      end

      [domain,
       domain_with_obtained_letsencrypt].each do |domain|
        expect(PagesDomainVerificationWorker).not_to receive(:perform_async).with(domain.id)
      end

      worker.perform
    end

    shared_examples 'does nothing' do
      it 'does nothing' do
        expect(PagesDomainSslRenewalWorker).not_to receive(:perform_async)

        worker.perform
      end
    end

    context 'when letsencrypt integration is disabled' do
      before do
        stub_application_setting(
          lets_encrypt_terms_of_service_accepted: false
        )
      end

      include_examples 'does nothing'
    end
  end
end