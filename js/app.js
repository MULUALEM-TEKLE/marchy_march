import * as THREE from "three";

import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";

import * as dat from "dat.gui";

import fragmentShader from "./shaders/fragment.glsl";
import vertexShader from "./shaders/vertex.glsl";

export default class Sketch {
  constructor(options) {
    this.container = options.dom;
    this.sizes = {
      width: this.container.offsetWidth,
      height: this.container.offsetHeight,
    };
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(this.sizes.width, this.sizes.height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(0xeeeeee, 0);
    this.renderer.sRGBEncoding = true;
    this.renderer.physicallyCorrectLights = true;
    this.container.appendChild(this.renderer.domElement);

    /* this.camera = new THREE.PerspectiveCamera(
      70,
      window.innerWidth / window.innerHeight,
      0.01,
      10
    );
    this.camera.position.z = 1; */

    this.clock = new THREE.Clock();

    let frustumSize = 1;
    let aspect = window.innerWidth / window.innerHeight;
    this.camera = new THREE.OrthographicCamera(
      frustumSize / -2,
      frustumSize / 2,
      frustumSize / 2,
      frustumSize / -2,
      -1000,
      1000
    );

    this.camera.position.z = 2;

    this.scene = new THREE.Scene();

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.enableRotate = false;
    this.controls.enableZoom = false;

    this.showSettings = true;

    this.time = 0;

    this.mouse = {
      x: 0,
      y: 0,
      prevX: 0,
      prevY: 0,
      vX: 0,
      vY: 0,
    };

    this.addObjects();
    this.resize();
    this.render();
    this.setupResize();
    this.settings();

    this.mouseEvents();
  }

  settings() {
    let that = this;
    this.settings = {
      sample: 0,
    };
    if (!this.showSettings) return;
    this.gui = new dat.GUI();
    this.gui.add(this.settings, "sample", 0, 8, 0.001).name("mann");
  }

  mouseEvents() {
    window.addEventListener("mousemove", (e) => {
      this.mouse.x = e.clientX / this.width;
      this.mouse.y = e.clientY / this.height;

      this.mouse.vX = this.mouse.x - this.mouse.prevX;
      this.mouse.vY = this.mouse.y - this.mouse.prevY;

      this.mouse.prevX = this.mouse.x;
      this.mouse.prevY = this.mouse.y;
    });
  }

  addObjects() {
    this.geometry = new THREE.PlaneBufferGeometry(1, 1, 100, 100);
    this.material = new THREE.ShaderMaterial({
      extensions: {
        derivatives: "extension GL_OES_standard_derivatives : enable",
      },
      fragmentShader,
      vertexShader,
      side: THREE.DoubleSide,
      uniforms: {
        time: { value: this.time },
        resolution: { value: new THREE.Vector4() },
      },
    });

    this.mesh = new THREE.Mesh(this.geometry, this.material);
    this.scene.add(this.mesh);
  }

  render() {
    this.time += this.clock.getDelta();
    this.material.uniforms.time.value = this.time;

    this.controls.update();

    this.renderer.render(this.scene, this.camera);
    window.requestAnimationFrame(this.render.bind(this));
  }

  setupResize() {
    window.addEventListener("resize", this.resize.bind(this));
  }

  resize() {
    console.log("resize works properly");
    this.sizes.width = this.container.offsetWidth;
    this.sizes.height = this.container.offsetHeight;
    this.renderer.setSize(this.sizes.width, this.sizes.height);
    this.camera.aspect = this.sizes.width / this.sizes.height;

    // image cover
    this.imageAspect = 1;
    let a1;
    let a2;
    if (this.sizes.height / this.sizes.width > this.imageAspect) {
      a1 = (this.sizes.width / this.sizes.height) * this.imageAspect;
      a2 = 1;
    } else {
      a1 = 1;
      a2 = this.sizes.height / this.sizes.width / this.imageAspect;
    }

    this.material.uniforms.resolution.value.x = this.sizes.width;
    this.material.uniforms.resolution.value.y = this.sizes.height;
    this.material.uniforms.resolution.value.z = a1;
    this.material.uniforms.resolution.value.w = a2;

    this.camera.updateProjectionMatrix();
  }
}

const canvas = new Sketch({
  dom: document.getElementById("container"),
});
