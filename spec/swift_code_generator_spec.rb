# frozen_string_literal: true

RSpec.describe SwiftCodeGenerator do
  let(:config) { Config.new(YAML.load_file("spec/fixtures/arkana-fixture.yml")) }
  let(:salt) { SaltGenerator.generate }
  let(:environment_secrets) do
    Encoder.encode!(
      keys: config.environment_keys,
      salt: salt,
      current_flavor: config.current_flavor,
      environments: config.environments,
    )
  end

  let(:global_secrets) do
    Encoder.encode!(
      keys: config.global_secrets,
      salt: salt,
      current_flavor: config.current_flavor,
      environments: config.environments,
    )
  end

  let(:template_arguments) do
    TemplateArguments.new(
      environment_secrets: environment_secrets,
      global_secrets: global_secrets,
      config: config,
      salt: salt,
    )
  end

  before do
    config.all_keys.each do |key|
      allow(ENV).to receive(:[]).with(key).and_return("value")
    end
  end

  after { FileUtils.rm_rf(config.result_path) }

  describe ".generate" do
    let(:swift_package_dir) { File.join(config.result_path, config.import_name) }
    let(:interface_swift_package_dir) { File.join(config.result_path, "#{config.import_name}Interfaces") }

    # NOTE: Can't use:
    # def path(...)
    #   Pathname.new(File.join(...))
    # end
    # Until the minimum target version is Ruby 2.7
    def path(arg1, arg2, arg3 = nil)
      arg1and2 = File.join(arg1, arg2)
      return Pathname.new(arg1and2) unless arg3
      return Pathname.new(File.join(arg1and2, arg3)) if arg3
    end

    it "should generate all necessary directories and files" do
      SwiftCodeGenerator.generate(template_arguments: template_arguments, config: config)
      expect(Pathname.new(config.result_path)).to be_directory
      expect(path(swift_package_dir, "README.md")).to be_file
      expect(path(swift_package_dir, "Package.swift")).to be_file
      expect(path(swift_package_dir, "Sources", "#{config.import_name}.swift")).to be_file
      expect(path(interface_swift_package_dir, "README.md")).to be_file
      expect(path(interface_swift_package_dir, "Package.swift")).to be_file
      expect(path(interface_swift_package_dir, "Sources", "#{config.import_name}Interfaces.swift")).to be_file
    end

    context "when 'config.package_manager'" do
      context "is 'cocoapods'" do
        before do
          allow(config).to receive(:package_manager).and_return("cocoapods")
          SwiftCodeGenerator.generate(template_arguments: template_arguments, config: config)
        end

        it "should generate podspec files" do
          expect(path(swift_package_dir, "#{config.pod_name.capitalize_first_letter}.podspec")).to be_file
          expect(path(interface_swift_package_dir, "#{config.pod_name.capitalize_first_letter}Interfaces.podspec")).to be_file
        end
      end

      context "is not 'cocoapods'" do
        before do
          allow(config).to receive(:package_manager).and_return("spm")
          SwiftCodeGenerator.generate(template_arguments: template_arguments, config: config)
        end

        it "should not generate podspec files" do
          expect(path(swift_package_dir, "#{config.pod_name.capitalize_first_letter}.podspec")).to_not be_file
          expect(path(interface_swift_package_dir, "#{config.pod_name.capitalize_first_letter}Interfaces.podspec")).to_not be_file
        end
      end
    end

    context "when 'config.should_generate_unit_tests' is true" do
      before do
        allow(config).to receive(:should_generate_unit_tests).and_return(true)
        SwiftCodeGenerator.generate(template_arguments: template_arguments, config: config)
      end

      it "should generate test folder and files" do
        expect(path(swift_package_dir, "Tests", "#{config.import_name}Tests.swift")).to be_file
      end

      it "should contain '.testTarget(' in Package.swift" do
        expect(File.read(path(swift_package_dir, "Package.swift"))).to match(/\.testTarget\(/)
      end
    end

    context "when 'config.should_generate_unit_tests' is false" do
      before do
        allow(config).to receive(:should_generate_unit_tests).and_return(false)
        SwiftCodeGenerator.generate(template_arguments: template_arguments, config: config)
      end

      it "should not generate test folder or files" do
        expect(path(swift_package_dir, "Tests", "#{config.import_name}Tests.swift")).to_not be_file
        expect(path(swift_package_dir, "Tests")).to_not be_directory
      end

      it "should not contain '.testTarget(' in Package.swift" do
        expect(File.read(path(swift_package_dir, "Package.swift"))).to_not match(/\.testTarget\(/)
      end
    end
  end
end
