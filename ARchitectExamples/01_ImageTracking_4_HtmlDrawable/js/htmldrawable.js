var World = {
    
hasVideoStarted:false,
init: function initFn() {
    this.createOverlays();
},
    
createOverlays: function createOverlaysFn() {
    
    this.targetCollectionResource = new AR.TargetCollectionResource("assets/tracker.wtc", {
                                                                    onError: World.onError
                                                                    });
    
    
    this.tracker = new AR.ImageTracker(this.targetCollectionResource, {
                                       onTargetsLoaded: World.showInfoBar,
                                       onError: World.onError
                                       });
    
    
    
    /***** mobiler *****/
    
    /* Create overlay for page one of the magazine. */
    var imgOne = new AR.ImageResource("assets/ornek.png", {
                                      onError: World.onError
                                      });
    var overlayOne = new AR.ImageDrawable(imgOne, 0.8, {
                                          translate: {
                                          x: -0.15,
                                          y: 1.3
                                          }
                                          });
    
    
    var playButtonImg = new AR.ImageResource("assets/playButton.png");
    var playButton = new AR.ImageDrawable(playButtonImg, 0.4, {
                                          enabled: false,
                                          clicked: false,
                                          zOrder: 2,
                                          onClick: function playButtonClicked() {
                                          video.play(1);
                                          video.playing = true;
                                          playButton.clicked = true;
                                          },
                                          translate: {
                                          y: -1.05
                                          }
                                          });
    
    var video = new AR.VideoDrawable("assets/appleVideo.mp4", 0.80, {
                                     translate: { y:-1.05,x:-0.15 },
                                     zOrder: 1,
                                     onLoaded: function videoLoaded() {
                                     playButton.enabled = true;
                                     },
                                     onPlaybackStarted: function videoPlaying() {
                                     playButton.enabled = false;
                                     video.enabled = true;
                                     },
                                     onFinishedPlaying: function videoFinished() {
                                     playButton.enabled = true;
                                     video.playing = false;
                                     video.enabled = false;
                                     },
                                     onClick: function videoClicked() {
                                     if (playButton.clicked) {
                                     playButton.clicked = false;
                                     } else if (video.playing) {
                                     video.pause();
                                     video.playing = false;
                                     } else {
                                     video.resume();
                                     video.playing = true;
                                     }
                                     }
                                     });
    
    
    this.imgButton = new AR.ImageResource("assets/wwwButton.jpg");
    
    var pageOneButton = this.createNativeButton( 0.3, {
                                                translate: {
                                                x: -0.25,
                                                y: -0.25
                                                },
                                                zOrder: 1
                                                });
    
    
    
    /***** mobiler ******/
    
    
    
    this.pageOne = new AR.ImageTrackable(this.tracker, "appleLogo", {
                                         drawables: {
                                         cam: [overlayOne, video, playButton, pageOneButton]
                                         },
                                         onImageRecognized: function onImageRecognizedFn() {
                                         if (video.playing) {
                                         video.resume();
                                         }
                                         World.removeLoadingBar();
                                         },
                                         onImageLost: function onImageLostFn() {
                                         if (video.playing) {
                                         video.pause();
                                         }
                                         },
                                         onError: function(errorMessage) {
                                         alert(errorMessage);
                                         }
                                         });
    
    
},
    
onError: function onErrorFn(error) {
    alert(error);
},
    
createNativeButton: function createNativeButtonFn( size, options) {
    
    options.onClick = function() {
        World.onDetailClicked();
    };
    return new AR.ImageDrawable(this.imgButton, size, options);
},
    
onDetailClicked: function onDetailClickedFn() {
    
    var markerSelectedJSON = {
        action: "present_native_details",
        title: "Apple detay sayfası",
        description: "İlgili ürünü bu sayfadan satın alabilirsiniz."
    };
    
    
    AR.platform.sendJSONObject(markerSelectedJSON);
},
    
hideInfoBar: function hideInfoBarFn() {
    document.getElementById("infoBox").style.display = "none";
},
    
showInfoBar: function worldLoadedFn() {
    document.getElementById("infoBox").style.display = "table";
    document.getElementById("loadingMessage").style.display = "none";
}
};

World.init();
