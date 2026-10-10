#
# micro_ocr (F12.2b): lato iOS = Vision di sistema. Nessuna dipendenza oltre a Flutter e ai
# framework di Apple (Vision, ImageIO): sull'iPhone niente ONNX Runtime ne' modelli.
#
Pod::Spec.new do |s|
  s.name             = 'micro_ocr'
  s.version          = '1.0.0'
  s.summary          = 'OCR solo sul telefono per le MicroApps (iOS: Vision).'
  s.description      = <<-DESC
OCR on-device: VNRecognizeTextRequest su iOS; le righe tornano a Dart con il riquadro di Vision.
                       DESC
  s.homepage         = 'https://smpmicroapps.it'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'SMP' => 'nbdy88@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'micro_ocr/Sources/micro_ocr/**/*.swift'
  s.dependency 'Flutter'
  s.frameworks = 'Vision', 'ImageIO'
  s.platform = :ios, '15.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'micro_ocr_privacy' => ['micro_ocr/Sources/micro_ocr/PrivacyInfo.xcprivacy']}
end
