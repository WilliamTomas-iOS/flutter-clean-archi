import 'package:dartz/dartz.dart';
import 'package:flutter_clean_archi/core/error/exceptions.dart';
import 'package:flutter_clean_archi/core/error/failures.dart';
import 'package:flutter_clean_archi/core/platform/network_info.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:flutter_clean_archi/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:flutter_clean_archi/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:flutter_clean_archi/features/number_trivia/domain/repositories/number_trivia_repository.dart';
import 'package:meta/meta.dart';

class NumberTriviaRepositoryImpl implements NumberTriviaRepository {
  final NumberTriviaRemoteDataSource remoteDataSource;
  final NumberTriviaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NumberTriviaRepositoryImpl({
    @required this.remoteDataSource,
    @required this.localDataSource,
    @required this.networkInfo
  });

  @override
  Future<Either<Failure, NumberTrivia>> getConcreteNumberTrivia(int number) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTrivia = await remoteDataSource.getConcreteNumberTrivia(
            number);
        localDataSource.cacheNumberTrivia(remoteTrivia);
        return Right(remoteTrivia);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localTrivia = await localDataSource.getLastNumberTrivia();
        return Right(localTrivia);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, NumberTrivia>> getRandomNumberTrivia() {
    // TODO: implement getRandomNumberTrivia
    throw UnimplementedError();
  }

}