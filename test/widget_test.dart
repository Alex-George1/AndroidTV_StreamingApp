import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:android_tv_streaming_app/models/video_item.dart';
import 'package:android_tv_streaming_app/models/video_category.dart';
import 'package:android_tv_streaming_app/viewmodels/home_viewmodel.dart';
import 'package:android_tv_streaming_app/services/video_service.dart';
import 'package:android_tv_streaming_app/views/home_screen.dart';

/// Mock video service that returns data without using rootBundle.
class MockVideoService extends VideoService {
  @override
  Future<List<VideoCategory>> loadCategories() async {
    return [
      VideoCategory(
        name: 'Test Category',
        videos: const [
          VideoItem(
            id: 't1',
            title: 'Test Video 1',
            description: 'Test description',
            thumbnailUrl: 'https://example.com/thumb1.jpg',
            videoUrl: 'https://example.com/video1.mp4',
            category: 'Test Category',
            duration: Duration(seconds: 60),
          ),
          VideoItem(
            id: 't2',
            title: 'Test Video 2',
            description: 'Test description 2',
            thumbnailUrl: 'https://example.com/thumb2.jpg',
            videoUrl: 'https://example.com/video2.mp4',
            category: 'Test Category',
            duration: Duration(seconds: 120),
          ),
        ],
      ),
    ];
  }
}

void main() {
  group('VideoItem model tests', () {
    test('VideoItem.fromJson creates correct model', () {
      final json = {
        'id': 'v1',
        'title': 'Test Video',
        'description': 'A test video',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'videoUrl': 'https://example.com/video.mp4',
        'category': 'Test',
        'durationSeconds': 120,
      };

      final video = VideoItem.fromJson(json);

      expect(video.id, 'v1');
      expect(video.title, 'Test Video');
      expect(video.description, 'A test video');
      expect(video.category, 'Test');
      expect(video.duration.inSeconds, 120);
    });

    test('VideoItem equality is based on id', () {
      const v1 = VideoItem(
        id: 'v1',
        title: 'Video 1',
        description: '',
        thumbnailUrl: '',
        videoUrl: '',
        category: 'Test',
      );
      const v2 = VideoItem(
        id: 'v1',
        title: 'Different Title',
        description: '',
        thumbnailUrl: '',
        videoUrl: '',
        category: 'Test',
      );
      expect(v1, equals(v2));
    });

    test('VideoItem.toJson produces correct map', () {
      const video = VideoItem(
        id: 'v1',
        title: 'Test',
        description: 'Desc',
        thumbnailUrl: 'thumb',
        videoUrl: 'url',
        category: 'Cat',
        duration: Duration(seconds: 60),
      );

      final json = video.toJson();
      expect(json['id'], 'v1');
      expect(json['durationSeconds'], 60);
    });
  });

  group('VideoCategory model tests', () {
    test('VideoCategory.fromJson creates correct model', () {
      final json = {
        'name': 'Action',
        'videos': [
          {
            'id': 'v1',
            'title': 'Test',
            'thumbnailUrl': '',
            'videoUrl': '',
            'category': 'Action',
          },
        ],
      };

      final category = VideoCategory.fromJson(json);
      expect(category.name, 'Action');
      expect(category.videos.length, 1);
      expect(category.videos[0].id, 'v1');
    });
  });

  group('HomeViewModel tests', () {
    test('Initial state is loading', () {
      final vm = HomeViewModel();
      expect(vm.isLoading, true);
      expect(vm.categories, isEmpty);
      expect(vm.error, isNull);
    });

    test('setFocusedItem updates focused item', () {
      final vm = HomeViewModel();
      const video = VideoItem(
        id: 'v1',
        title: 'Test',
        description: '',
        thumbnailUrl: '',
        videoUrl: '',
        category: '',
      );

      vm.setFocusedItem(video);
      expect(vm.focusedItem, video);

      vm.setFocusedItem(null);
      expect(vm.focusedItem, isNull);
    });

    test('loadVideos loads categories from service', () async {
      final vm = HomeViewModel(videoService: MockVideoService());

      await vm.loadVideos();

      expect(vm.isLoading, false);
      expect(vm.error, isNull);
      expect(vm.categories, isNotEmpty);
      expect(vm.categories.first.name, 'Test Category');
      expect(vm.categories.first.videos.length, 2);
      vm.dispose();
    });

    test('allVideos returns flat list from all categories', () async {
      final vm = HomeViewModel(videoService: MockVideoService());
      await vm.loadVideos();

      expect(vm.allVideos.length, 2);
      expect(vm.allVideos[0].id, 't1');
      expect(vm.allVideos[1].id, 't2');
      vm.dispose();
    });
  });

  group('HomeScreen widget tests', () {
    testWidgets('Shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(videoService: MockVideoService()),
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

