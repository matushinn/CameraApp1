//
//  ViewController.swift
//  CameraApp1
//
//  Created by 大江祥太郎 on 2019/01/08.
//  Copyright © 2019年 shotaro. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class ViewController: UIViewController ,AVCapturePhotoCaptureDelegate{
    
    //AVCapture立ち上げ
    var captureSession = AVCaptureSession()
    
    //バックカメラかフロントカメラか現在のカメラかの選択
    var backCamera:AVCaptureDevice?
    
     var frontCamera:AVCaptureDevice?
    
     var currentCamera:AVCaptureDevice?
    
    //写真のアウトプット
    var Output:AVCapturePhotoOutput?
    var PreviewLayer:AVCaptureVideoPreviewLayer?
    
    //撮影したら入る箱
    var image:UIImage?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //カメラの許可を出す
        PHPhotoLibrary.requestAuthorization { (status) in
            switch(status){
            case .notDetermined:
                print("notDetermined")
            case .restricted:
                print("restricted")
            case .denied:
                print("denied")
            case .authorized:
                print("許可")
                
            }
        }
        
        //DispatchQueueを行うことでディスパッチ内の処理を順に行うことができるようになります。
        //設定を上から順に読み込んでい最後にstartRunningCaptureSessionを読み込ませることで正しく起動させる処理にすることができました。
        DispatchQueue.main.async {
            self.setUpCaptureSession()
            self.setUpDevice()
            self.setUpInputOutput()
            self.setUpPreviewLayer()
            self.startRunningCaptureSession()
        }
    }
    
    //最後に撮影した写真を次の画面に渡す処理を書いてViewControllerは完了。
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "next"{
            
            let preVC = segue.destination as! PreViewController
            preVC.image = self.image!
            
        }
    }
    //カメラの画質を決定する値を設定
    //高解析度の画像出力ができるphotoを設定する
    func setUpCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    /*デバイスの設定＊*/
    //AVCaptureDeviceクラスはカメラやマイクなどのデバイス本体の設定管理を行います。
    //AVCaptureDevice.DiscoverySessionクラスでカメラデバイスの種類(deviceType)
    //取得するメディアの種類
    //FaceTimeカメラとiSightカメラ(position)
    
    //今回は、カメラの種類は広角カメラ(buildWideAngleCamera),メディアの種類は描画(video)
    //FaceTimeカメラとiSightカメラのどちらも(unspecified)を設定しています。
    //取得したデバイスのセッションから利用可能なデバイスをdevicesメソッドで取得し、FaceTimeカメラとiSightカメラそれぞれの管理のオブジェクトに代入しています。
    //アプリ起動時に使用するカメラを設定が必要で、今回は、iSightカメラ(背面のカメラ)を使用するので、PositionがBackのカメラを設定します。
    
    func setUpDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        let device = deviceDiscoverySession.devices
        
        for device in device{
            if device.position == AVCaptureDevice.Position.back{
                backCamera = device
            }else if device.position == AVCaptureDevice.Position.back{
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    /*入力データの設定*/
    
    //デバイスのカメラの入力のを初期化
    //設定したデバイスの情報をAVCaptureDeviceInputクラスを用いて、AVCaptureSessionに追加しています。
    
    //次にキャプチャーの出力データであるAVCapturePhotoOutputオブジェクトを作成。
    //オブジェクトを作成後、setPreparedPhotoSettingsArrayに追加し、入力、出力データの設定が完了です。
    
    func setUpInputOutput(){
        do{
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            
            output = AVCapturePhotoOutput()

        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey:AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput)

        }catch {
            print(error)
        }
    }
    
    /*カメラの取得している映像の表示*/
    
    //カメラ表示用のレイヤーの設定。
    
    //カメラの取得している映像を画面に表示するには、AVCaptureVideoPreviewLayerクラスを用います。
    //AVCaptureVideoPreviewLayerクラスは、描画コンテンツを管理しているCALayerクラスのサブクラスです。
    
    //作成するレイヤーの設定を行います。
    //まず、指定するAVCaptureSessionオブジェクトでAVCaptureVideoPreviewLayerオブジェクトを初期化します。
    //次にレイヤーの構成を行います。
    //videoGravityプロパティでプレビューレイヤが、カメラからの映像をどのように表示するかを設定します。
    
    //タテヨコ比を維持したまま表示するため、AVLayerVideoGravityのresizeAspectFillを設定します。
    
    //次に、connectionプロパティのvideoOrientationプロパティで、表示するプレビューレイヤの向きを指定します。
    //カメラのキャプチャーをそのままの向きで表示するため、定数AVCaptureVideoOrientation.portraitを設定します。
    
    //最後にレイヤのフレームにビューのフレームを設定します。
    //これでレイヤの設定は終了です。最後にこのAVCaptureVideoPreviewLayerオブジェクトをビューのレイヤに追加することで、カメラのキャプチャが画面に表示するように設定します。
 
    func setUpPreviewLayer(){
        PreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        PreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        PreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(PreviewLayer!, at: 0)
    }
    
    //AVCaptureSessionクラスのstartRunningメソッドを起動することで、セッションの入力から出力データの流れを開始し、画面にカメラのキャプチャーを表示することができます。
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }
    
    @IBAction func cameraButton(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    //写真を撮ったら次のページに渡す処理を書いていきましょう。
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageDate = photo.fileDataRepresentation(){
            
            image = UIImage(data: imageDate)!
            performSegue(withIdentifier: "next", sender: nil)
            
            
        }
    }
    

    


}

