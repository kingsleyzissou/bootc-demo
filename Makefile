build:
	sudo podman build \
	--no-hostname \
	--build-arg=HOSTNAME=$(hostname) \
	--build-context=container-auth="${HOME}/.config/ostree" \
	--arch=amd64 \
	--tag quay.io/gzuccare/bootc:$(hostname) .

image:
	sudo podman run \
	--rm \
	-it \
	--privileged \
	--pull=newer \
	--security-opt label=type:unconfined_t \
	-v ./config.json:/config.json \
	-v ./output:/output \
	-v /var/lib/containers/storage:/var/lib/containers/storage \
	quay.io/centos-bootc/bootc-image-builder:latest \
	build \
	--type qcow2 \
	--target-arch x86_64 \
	--config /config.json \
	--rootfs ext4 \
	--local \
	quay.io/gzuccare/bootc:$(tag)

vm:
	qemu-system-x86_64 -smp 8 \
	-cpu host \
	-m 16G \
	-accel kvm \
	-drive file=output/qcow2/disk.qcow2,format=qcow2 \
	-device virtio-net-pci,netdev=n0,mac=FE:0B:6E:22:3D:00 \
	-netdev user,id=n0,net=10.0.2.0/24,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:80 \
	-nographic \
	-serial mon:stdio

container:
	podman run -d --rm -it -p 8001:80 --name "demo" localhost/demo

slides:
	podman run --rm -p 1948:1948 -p 35729:35729 -v ./demo:/slides webpronl/reveal-md:latest /slides --theme white --watch
