# https://makefiletutorial.com/

run_stub:
	bash ./data/mock_data/generate_mock_files.sh && nextflow run main.nf -entry TEST -stub-run

run_dev:
	nextflow run main.nf -profile dev -resume -with-tower

run_test:
	nextflow run main.nf -params-file params/test.yml -entry TEST -resume -profile standard,docker
