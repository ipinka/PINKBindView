Pod::Spec.new do |s|
  s.name             = "PINKBindView"
  s.version          = "2.0.1"
  s.summary          = "PINKBindView provide a simple way to use tableView and collectionView."
  s.description      = <<-DESC
                       PINKBindView provide a simple way to use tableView and collectionView.

                       * You can write less code.
                       * Reload view automatically.
                       * Bind data by a better way.
                       DESC
  s.homepage         = "https://github.com/ipinka/PINKBindView"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "Pinka"
  s.source           = { :git => "https://github.com/ipinka/PINKBindView.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'PINKBindView'

  s.dependency 'ReactiveCocoa', '~> 2.3'
end
