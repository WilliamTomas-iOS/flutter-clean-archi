import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_clean_archi/core/error/exceptions.dart';
import 'package:flutter_clean_archi/core/error/failures.dart';
import 'package:flutter_clean_archi/core/platform/network_info.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/models/number_trivia_model.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/repositories/number_trivia_repository_impl.dart';
import 'package:flutter_clean_archi/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockRemoteDataSource extends Mock implements NumberTriviaRemoteDataSource {

}

class MockLocalDataSource extends Mock implements NumberTriviaLocalDataSource {

}

class MockNetworkInfo extends Mock implements NetworkInfo {

}

void main() {
  NumberTriviaRepositoryImpl repository;
  MockRemoteDataSource mockRemoteDataSource;
  MockLocalDataSource mockLocalDataSource;
  MockNetworkInfo mockNetworkInfo;

  setUp (() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = NumberTriviaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getConcreteNumberTrivia', () {
    final tNumber = 1;
    final tNumberTriviaModel = NumberTriviaModel(text: 'test trivia', number: tNumber);
    final NumberTrivia tNumberTrivia = tNumberTriviaModel;

    test(
      'should check if the device is online',
      () async {
        //arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        //act
        repository.getConcreteNumberTrivia(tNumber);
        //assert
        verify(mockNetworkInfo.isConnected);
      },
    );

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test(
        'should return remote data when the call to remote data source is successful',
        () async {
          //arrange
          when(mockRemoteDataSource.getConcreteNumberTrivia(any)).thenAnswer((_) async => tNumberTriviaModel);
          //act
          final result = await repository.getConcreteNumberTrivia(tNumber);
          //assert
          verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
          expect(result, Right(tNumberTrivia));
        },
      );

      test(
        'should cache the data locally when the call to remote data source is successful',
        () async {
          //arrange
          when(mockRemoteDataSource.getConcreteNumberTrivia(any)).thenAnswer((_) async => tNumberTriviaModel);
          //act
          await repository.getConcreteNumberTrivia(tNumber);
          //assert
          verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
          verify(mockLocalDataSource.cacheNumberTrivia(tNumberTriviaModel));
        },
      );

      test(
        'should return server failure when the call to remote data source is unsuccessful',
        () async {
          //arrange
          when(mockRemoteDataSource.getConcreteNumberTrivia(any)).thenThrow(ServerException());
          //act
          final result = await repository.getConcreteNumberTrivia(tNumber);
          //assert
          verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
          verifyZeroInteractions(mockLocalDataSource); //on ne veut pas mettre en cache lors d'une erreur serveur
          expect(result, Left(ServerFailure()));
        },
      );
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test(
        'should return last locally cached data when the cached data is present',
        () async {
          //arrange
          when(mockLocalDataSource.getLastNumberTrivia()).thenAnswer((_) async => tNumberTriviaModel);
          //act
          final result = await repository.getConcreteNumberTrivia(tNumber);
          //assert
          verifyZeroInteractions(mockRemoteDataSource);
          verify(mockLocalDataSource.getLastNumberTrivia());
          expect(result, Right(tNumberTrivia));
        },
      );

      test(
        'should return CacheFailure when their is no cached data present',
        () async {
          //arrange
          when(mockLocalDataSource.getLastNumberTrivia()).thenThrow(CacheException());
          //act
          final result = await repository.getConcreteNumberTrivia(tNumber);
          //assert
          verifyZeroInteractions(mockRemoteDataSource);
          verify(mockLocalDataSource.getLastNumberTrivia());
          expect(result, Left(CacheFailure()));
        },
      );
    });
  });
}