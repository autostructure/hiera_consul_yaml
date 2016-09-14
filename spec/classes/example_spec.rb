require 'spec_helper'

describe 'hiera_consul_yaml' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "hiera_consul_yaml class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('hiera_consul_yaml::params') }
          it { is_expected.to contain_class('hiera_consul_yaml::install').that_comes_before('hiera_consul_yaml::config') }
          it { is_expected.to contain_class('hiera_consul_yaml::config') }
          it { is_expected.to contain_class('hiera_consul_yaml::service').that_subscribes_to('hiera_consul_yaml::config') }

          it { is_expected.to contain_service('hiera_consul_yaml') }
          it { is_expected.to contain_package('hiera_consul_yaml').with_ensure('present') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'hiera_consul_yaml class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_package('hiera_consul_yaml') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
