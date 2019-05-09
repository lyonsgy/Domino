//
//  ARSCNViewController.swift
//  Domino
//
//  Created by lyons on 2019/5/9.
//  Copyright © 2019 lyons. All rights reserved.
//

import UIKit
//3D游戏框架
import SceneKit
//ARKit框架
import ARKit

class ARSCNViewController: UIViewController {
    
    lazy var arSCNView: ARSCNView! = {
        //1.创建AR视图
        var arSCNView = ARSCNView.init(frame: self.view.bounds)
        //2.设置视图会话
        arSCNView.session = self.arSession;
        //3.自动刷新灯光（3D游戏用到，此处可忽略）
        arSCNView.automaticallyUpdatesLighting = true;
        return arSCNView;
    }()
    lazy var arSession: ARSession! = {
        var arSession = ARSession.init()
        return arSession
    }()
    lazy var arConfiguration: ARConfiguration! = {
        //1.创建世界追踪会话配置（使用ARWorldTrackingSessionConfiguration效果更加好），需要A9芯片支持
        var configuration = ARWorldTrackingConfiguration.init()
        //2.设置追踪方向（追踪平面，后面会用到）
        configuration.planeDetection = .horizontal
        //3.自适应灯光（相机从暗到强光快速过渡效果会平缓一些）
        configuration.isLightEstimationEnabled = true
        return configuration
    }()
    lazy var planeNode: SCNNode! = {
        /*
         1.使用场景加载scn文件（scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建，这里系统有一个默认的3D飞机）
         在右侧我添加了许多3D模型，只需要替换文件名即可
         */
        let scene = SCNScene.init(named: "art.scnassets/ship.scn")
        /*
         2.获取飞机节点（一个场景会有多个节点，此处我们只写，飞机节点则默认是场景子节点的第一个）
         所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
         */
        let planeNode = scene?.rootNode.childNodes[0]
        return planeNode
    }()
    lazy var rightBtn: UIButton! = {
        let rightBtn = UIButton.init()
        rightBtn.setTitle("transform", for: UIControl.State.normal)
        rightBtn.addTarget(self, action: #selector(transfromBtnClick(sender:)), for: UIControl.Event.touchUpInside)
        return rightBtn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ARSCN"
        let rightBarBtnItem:UIBarButtonItem = UIBarButtonItem.init(customView: rightBtn)
        self.navigationItem.rightBarButtonItem = rightBarBtnItem;
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //1.将AR视图添加到当前视图
        view.addSubview(arSCNView)
        //2.开启AR会话（此时相机开始工作）
        arSession.run(arConfiguration)
    }
    @objc func transfromBtnClick(sender: UIButton) {
        guard (planeNode != nil) else {
            return
        }
        //旋转核心动画
        let moonRotationAnimation = CABasicAnimation.init(keyPath: "rotation")
        //旋转周期
        moonRotationAnimation.duration = 5
        //围绕Y轴旋转360度  （不明白ARKit坐标系的可以看笔者之前的文章）
        moonRotationAnimation.toValue = NSValue.init(scnVector4: SCNVector4Make(0, 1, 0, Float(Double.pi * 2)))
        //无限旋转  重复次数为无穷大
        moonRotationAnimation.repeatCount = .greatestFiniteMagnitude
        
        //开始旋转  ！！！：切记这里是让空节点旋转，而不是台灯节点。  理由同上
        planeNode.addAnimation(moonRotationAnimation, forKey: "moon rotation around earth")
    }
}

extension ARSCNViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
       
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for item:SCNNode in arSCNView.scene.rootNode.childNodes {
            guard item.name != planeNode!.name else {
                return
            }
        }
//        planeNode.eulerAngles = SCNVector3Make(0, -90, 0)

        //3.将飞机节点添加到当前屏幕中
        arSCNView.scene.rootNode.addChildNode(planeNode!)
        print(arSCNView.scene.rootNode.childNodes.count)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        planeNode?.position = get3DPoint(touches: touches)
    }
    
    /// 触摸2D坐标转换3D坐标
    func get3DPoint(touches: Set<UITouch>) -> SCNVector3 {
        var touch : UITouch!
        touch = touches.first
        let touchPoint = touch.location(in: touch.view)
        
        let arrayResult: [ARHitTestResult] = arSCNView.hitTest(touchPoint, types: ARHitTestResult.ResultType.featurePoint)
        guard arrayResult.count>0 else {
            return SCNVector3Make(0, 0, 0)
        }
        let point3D = arrayResult[0].worldTransform.columns.3
        let centerVector3:SCNVector3 = SCNVector3Make(point3D.x, point3D.y, point3D.z)
        print(centerVector3)
        return centerVector3
    }
}

