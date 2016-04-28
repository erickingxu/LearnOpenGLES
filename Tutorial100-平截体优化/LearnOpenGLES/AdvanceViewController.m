//
//  AdvanceViewController.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/25.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "AdvanceViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKFrustum.h"
#import "sphere.h"

@interface AdvanceViewController ()

@property (nonatomic , strong) EAGLContext* mContext;

@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexPositionBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexNormalBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexTextureCoordBuffer;

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (assign, nonatomic) float filteredFPS;
@property (assign, nonatomic) AGLKFrustum frustum;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) BOOL shouldCull;
@property (assign, nonatomic) float yawAngleRad;

@property (nonatomic , strong) UILabel* fpsField;

- (IBAction)takeShouldUsePerspectiveFrom:(UISwitch *)aControl;

@end

@implementation AdvanceViewController
{
}

static const GLKVector3 ScenePosition = {50.0f, 0.0f, 50.0f};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView* view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    glEnable(GL_DEPTH_TEST);
//    glEnable(GL_CULL_FACE);
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    // Configure a light
    [self configureLight];
    
    // buffer data
    [self bufferData];
    
    self.fpsField = [[UILabel alloc] initWithFrame:CGRectMake(30, 30, 10, 10)];
    [self.fpsField setTextColor:[UIColor yellowColor]];
    [self.view addSubview:self.fpsField];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureLight
{
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(
                                                         1.0f, // Red
                                                         1.0f, // Green
                                                         1.0f, // Blue
                                                         1.0f);// Alpha
    self.baseEffect.light0.position = GLKVector4Make(
                                                     1.0f,  
                                                     0.8f,
                                                     0.4f,
                                                     0.0f);
    self.baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.2f, // Red 
                                                         0.2f, // Green 
                                                         0.2f, // Blue 
                                                         1.0f);// Alpha 
}


- (void)setClearColor:(GLKVector4)clearColorRGBA
{
    glClearColor(
                 clearColorRGBA.r,
                 clearColorRGBA.g,
                 clearColorRGBA.b,
                 clearColorRGBA.a);
}

- (void)bufferData {
    //顶点数据缓存
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                 initWithAttribStride:(3 * sizeof(GLfloat))
                                 numberOfVertices:sizeof(sphereVerts) / (3 * sizeof(GLfloat))
                                 bytes:sphereVerts
                                 usage:GL_STATIC_DRAW];
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                               initWithAttribStride:(3 * sizeof(GLfloat))
                               numberOfVertices:sizeof(sphereNormals) / (3 * sizeof(GLfloat))
                               bytes:sphereNormals
                               usage:GL_STATIC_DRAW];
    self.vertexTextureCoordBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                     initWithAttribStride:(2 * sizeof(GLfloat))
                                     numberOfVertices:sizeof(sphereTexCoords) / (2 * sizeof(GLfloat))
                                     bytes:sphereTexCoords
                                     usage:GL_STATIC_DRAW];
    
    
    [self.vertexPositionBuffer
     prepareToDrawWithAttrib:GLKVertexAttribPosition
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexNormalBuffer
     prepareToDrawWithAttrib:GLKVertexAttribNormal
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexTextureCoordBuffer
     prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
     numberOfCoordinates:2
     attribOffset:0
     shouldEnable:YES];

    //地球纹理
    CGImageRef earthImageRef = [[UIImage imageNamed:@"Earth512x256.jpg"] CGImage];
    GLKTextureInfo* earthTextureInfo = [GLKTextureLoader
                        textureWithCGImage:earthImageRef
                        options:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES],
                                 GLKTextureLoaderOriginBottomLeft, nil]
                        error:NULL];
    self.baseEffect.texture2d0.name = earthTextureInfo.name;
    self.baseEffect.texture2d0.target = earthTextureInfo.target;
    
    //矩阵堆
}

//地球
- (void)drawEarth
{
    GLKMatrixStackRef modelviewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    
    GLKMatrixStackLoadMatrix4(modelviewMatrixStack,
                              self.baseEffect.transform.modelviewMatrix);
    
    GLKMatrixStackPush(modelviewMatrixStack);
    
//    static int radiansX = 25;
//    GLKMatrixStackRotate(modelviewMatrixStack,
//                         GLKMathDegreesToRadians(radiansX),
//                         1.0, 0.0, 0.0);
//  
//    static int radiansY = 0;
//    
//    GLKMatrixStackRotate(modelviewMatrixStack,
//                         GLKMathDegreesToRadians(++radiansY),
//                         0.0, 1.0, 0.0);
    
    
    for(NSInteger i = -10; i < 5; i++)
    {
        for(NSInteger j = -10; j < 5; j++)
        {
            const GLKVector3 addPosition = {
                ScenePosition.x / 5 * i,
                0.0f,
                ScenePosition.z / 5 * j
            };
            
            if(!self.shouldCull || AGLKFrustumOut != AGLKFrustumCompareSphere(&_frustum, addPosition, 1))
            {
                GLKMatrixStackPush(modelviewMatrixStack);
                GLKMatrixStackTranslate(modelviewMatrixStack, addPosition.x, addPosition.y, addPosition.z);
                self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(modelviewMatrixStack);
                GLKMatrixStackPop(modelviewMatrixStack);
                [self.baseEffect prepareToDraw];
                
                [AGLKVertexAttribArrayBuffer
                 drawPreparedArraysWithMode:GL_TRIANGLES
                 startVertexIndex:0
                 numberOfVertices:sphereNumVerts];
            }
            else {
//                NSLog(@"%ld %ld out", i, j);
            }
            
        }
    }
    
    GLKMatrixStackPop(modelviewMatrixStack);
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(modelviewMatrixStack);
}

- (IBAction)takeShouldUsePerspectiveFrom:(UISwitch *)aControl;
{
    self.shouldCull = aControl.on;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            interfaceOrientation !=
            UIInterfaceOrientationPortrait);
}

/**
 *  场景数据变化
 */
- (void)update {
    
    const NSTimeInterval elapsedTime = [self timeSinceLastUpdate];
    
    if(0.0 < elapsedTime)
    {
        const float unfilteredFPS = 1.0f / elapsedTime;
        // add part of the difference between current filtered FPS
        // and unfilteredFPS (simple low pass filter)
        self.filteredFPS += 0.2f * (unfilteredFPS - self.filteredFPS);
    }
    
    self.fpsField.text = [NSString stringWithFormat:@"%03.1f FPS",
                          self.filteredFPS];
    [self.fpsField sizeToFit];
}

- (void)calculateFrustum {
    
    if(self.orientationDidChange ||
       !AGLKFrustumHasDimention(&_frustum))
    {
        GLfloat   aspectRatio =
        (self.view.bounds.size.width) /
        (self.view.bounds.size.height);
        const GLfloat fieldOfViewDeg = 5.0f;
        const GLfloat nearDistance = 1.0f;
        const GLfloat farDistance = 10000.0f;
        const GLfloat fieldOfViewRad =
        GLKMathDegreesToRadians(fieldOfViewDeg);
        
        // Initialize the frustum with same perspective parameters
        // used by GLKMatrix4MakePerspective()
        self.frustum = AGLKFrustumMakeFrustumWithParameters(
                                                            fieldOfViewRad,
                                                            aspectRatio,
                                                            nearDistance,
                                                            farDistance);
        
        // Set the base effect's projection matrix to match frustum
        self.baseEffect.transform.projectionMatrix = 
        AGLKFrustumMakePerspective(&_frustum);
    }
    
    self.yawAngleRad = 0.1f * [self timeSinceLastResume];
    
    // Use reasonable eye position and up direction
    static const GLKVector3 eyePosition = {
        0.0, 5.0, 0.0
    };
    static const GLKVector3 upDirection = {
        0.0, 1.0, 0.0
    };
    
    // Calculate current look-at position
    const GLKVector3 lookAtPosition = {
        ScenePosition.x * sinf(self.yawAngleRad),
        ScenePosition.y,
        ScenePosition.z * cosf(self.yawAngleRad)
    };
    
    // Configure the frustum field of view with same parameters
    // used by GLKMatrix4MakeLookAt()
    AGLKFrustumSetPositionAndDirection(
                                       &_frustum,
                                       eyePosition,
                                       lookAtPosition,
                                       upDirection);
    
    // Set the base effect's modelview matrix to match frustum
    self.baseEffect.transform.modelviewMatrix =  
    AGLKFrustumMakeModelview(&_frustum);
}


/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self calculateFrustum];
    [self drawEarth];

}


@end
